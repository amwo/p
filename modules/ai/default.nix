{ config, lib, pkgs, ... }:

let
  dir = ./.;

  common = builtins.readFile "${dir}/common.md";
  toolSpecific = tool: builtins.readFile "${dir}/tools/${tool}.md";
  fullContent = tool: ''
    ${common}

    # Tool-specific
    ${toolSpecific tool}
  '';
  cursorRule = ''
    ---
    description: Common AI agent rules
    globs:
    alwaysApply: true
    ---

    ${fullContent "cursor"}
  '';

  skillsDir = "${dir}/skills";
  skillNames = lib.filter (name: name != ".system") (
    lib.attrNames (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
    )
  );
  agentsDir = "${dir}/agents";
  agentCommon = pkgs.writeText "agent-common.md" common;
  buildAgentsDir = name: extraCommands: pkgs.runCommand name { } ''
    cp -r ${agentsDir} "$out"
    chmod -R u+w "$out"
    for file in "$out"/*.md; do
      tmp="$file.tmp"
      awk -v commonFile="${agentCommon}" '
        BEGIN {
          while ((getline line < commonFile) > 0) {
            common = common line "\n"
          }
          close(commonFile)
        }
        NR == 1 && $0 == "---" {
          print
          inFrontmatter = 1
          next
        }
        inFrontmatter && $0 == "---" {
          print
          print ""
          printf "%s\n", common
          inFrontmatter = 0
          next
        }
        { print }
      ' "$file" > "$tmp"
      mv "$tmp" "$file"
    done
    ${extraCommands}
  '';
  claudeAgentsDir = buildAgentsDir "claude-agents" "";
  geminiAgentsDir = buildAgentsDir "gemini-agents" ''
    for file in "$out"/*.md; do
      sed -i \
        -e 's/"Read"/"read_file"/g' \
        -e 's/"Write"/"write_file"/g' \
        -e 's/"Edit"/"replace"/g' \
        -e 's/"Bash"/"run_shell_command"/g' \
        -e 's/"Grep"/"grep_search"/g' \
        -e 's/"Glob"/"glob"/g' \
        -e '/^model: opus$/d' \
        "$file"
    done
  '';
  rulesDir = "${dir}/rules";
  dirExists = path: builtins.pathExists path;

  mcpServers = {
    context7 = {
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp" ];
    };
    github = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-github" ];
    };
    vercel = {
      type = "http";
      url = "https://mcp.vercel.com";
    };
    memory = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-memory" ];
    };
    sequential-thinking = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
    };
    effect-mcp = {
      command = "npx";
      args = [ "-y" "@niklaserik/effect-mcp" ];
    };
    svelte-mcp = {
      command = "npx";
      args = [ "-y" "@sveltejs/mcp" ];
    };
    storybook-mcp = {
      type = "http";
      url = "http://localhost:6006/mcp";
    };
    vuetify-mcp = {
      command = "npx";
      args = [ "-y" "@vuetify/mcp" ];
    };
    next-devtools-mcp = {
      command = "npx";
      args = [ "-y" "next-devtools-mcp" ];
    };
    playwright = {
      command = "npx";
      args = [ "-y" "@playwright/mcp" ];
    };
  };

  mcpJson = builtins.toJSON { inherit mcpServers; };

  commandBasedServers = lib.filterAttrs (_: cfg: cfg ? command) mcpServers;
  codexToml = ''
    approval_policy = "never"
    sandbox_mode = "danger-full-access"
  '' + lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: cfg: ''
      [mcp_servers.${name}]
      command = "${cfg.command}"
      args = [${lib.concatMapStringsSep ", " (a: ''"${a}"'') cfg.args}]
    '') commandBasedServers
  );

in
{
  home.file = {
    ".claude/CLAUDE.md".text = fullContent "claude";
    ".codex/AGENTS.md".text = fullContent "codex";
    ".gemini/GEMINI.md".text = fullContent "gemini";

    ".claude/skills" = { source = skillsDir; force = true; };
    ".gemini/skills" = { source = skillsDir; force = true; };

    ".claude/agents" = { source = claudeAgentsDir; force = true; };
    ".gemini/agents" = { source = geminiAgentsDir; force = true; };

  } // lib.optionalAttrs (dirExists rulesDir) {
    ".claude/rules" = { source = rulesDir; force = true; };
  } // {
    # NOTE: ~/.codex/config.toml is intentionally NOT managed here. The official
    # agentmemory Codex integration (`codex plugin add`) mutates config.toml at
    # runtime to register the plugin + its hooks, which fails against a read-only
    # Nix store symlink. config.toml is therefore owned by codex; YOLO defaults
    # and base MCP servers are seeded once as a real file (see codexToml below /
    # docs). Re-seed manually if you change the shared mcpServers list.
    ".cursor/mcp.json".text = mcpJson;
    ".cursor/rules/common.mdc" = {
      text = cursorRule;
      force = true;
    };
  } // lib.listToAttrs (
    map (name: {
      name = ".codex/skills/${name}";
      value = {
        source = "${skillsDir}/${name}";
        force = true;
      };
    }) skillNames
  );

  home.activation.removeConflictingDirs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f "$HOME/.claude.json"
    rm -f "$HOME/.codex/instructions.md"

    if [ -L "$HOME/.codex/skills" ]; then
      rm -f "$HOME/.codex/skills"
    fi
    mkdir -p "$HOME/.codex/skills"
    for skill in ${lib.concatStringsSep " " skillNames}; do
      if [ -e "$HOME/.codex/skills/$skill" ] || [ -L "$HOME/.codex/skills/$skill" ]; then
        rm -rf "$HOME/.codex/skills/$skill"
      fi
    done

    for dir in \
      "$HOME/.claude/skills" \
      "$HOME/.claude/agents" \
      "$HOME/.claude/rules" \
      "$HOME/.gemini/skills" \
      "$HOME/.gemini/agents"
    do
      if [ -d "$dir" ] && [ ! -L "$dir" ]; then
        rm -rf "$dir"
      fi
    done
  '';

  home.activation.claudeMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.claude/settings.json"
    mkdir -p "$HOME/.claude"
    rm -f "$target"
    install -m 600 ${pkgs.writeText "claude.json" mcpJson} "$target"
  '';

  home.activation.geminiSettingsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.gemini/settings.json"
    mkdir -p "$HOME/.gemini"
    if [ ! -e "$target" ] || [ -L "$target" ]; then
      rm -f "$target"
      install -m 600 ${pkgs.writeText "gemini-settings.json" mcpJson} "$target"
    fi
  '';
}
