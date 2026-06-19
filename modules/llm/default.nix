{ config, lib, pkgs, ... }:

let
  dir = ./.;

  # Compile hooks.json (the IR) into each LLM's native hook config at apply time.
  hooksCompiled = import ./hooks/compile.nix { inherit lib pkgs; };

  instructions = builtins.readFile "${dir}/AGENTS.md";

  claudeContent = ''
    ${instructions}

    @/home/am/.claude/RTK.md
  '';
  codexContent = ''
    # Critical Runtime Rule

    **All shell commands must be executed via `rtk`.**

    If you are about to call `exec_command`, the command string must begin
    with:

    ```bash
    rtk ...
    ```

    No exceptions unless explicitly approved by the user.

    This rule applies to all shell commands executed through Codex tools.
    Do not run raw commands like `sed`, `rg`, `git`, `npm`, `cargo`, or
    `pytest` directly.

    Examples:

    - `rtk rg "foo" .`
    - `rtk sed -n '1,120p' package.json`
    - `rtk git status`

    ${instructions}
  '';
  cursorRule = ''
    ---
    description: Common AI agent rules
    globs:
    alwaysApply: true
    ---

    ${instructions}
  '';

  skillsDir = "${dir}/skills";
  skillNames = lib.filter (name: name != ".system") (
    lib.attrNames (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
    )
  );
  agentsDir = "${dir}/agents";
  agentCommon = pkgs.writeText "agent-common.md" instructions;
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
        -e '/^model: sonnet$/d' \
        "$file"
    done
  '';
  mcpServers = {
    context7 = {
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp" ];
    };
    github = {
      # official GitHub MCP (the @modelcontextprotocol/server-github package is archived)
      type = "http";
      url = "https://api.githubcopilot.com/mcp/";
    };
    vercel = {
      type = "http";
      url = "https://mcp.vercel.com";
    };
    effect-mcp = {
      command = "npx";
      args = [ "-y" "@niklaserik/effect-mcp" ];
    };
    storybook-mcp = {
      type = "http";
      url = "http://localhost:6006/mcp";
    };
    next-devtools-mcp = {
      command = "npx";
      args = [ "-y" "next-devtools-mcp" ];
    };
    playwright = {
      command = "npx";
      args = [ "-y" "@playwright/mcp" ];
    };
    solana = {
      type = "http";
      url = "https://mcp.solana.com/mcp";
    };
    chrome-devtools = {
      command = "npx";
      args = [ "-y" "chrome-devtools-mcp" ];
    };
    xcodebuildmcp = {
      command = "npx";
      args = [ "-y" "xcodebuildmcp" ];
    };
    figma = {
      # Figma official Dev Mode MCP (desktop app must be running with Dev Mode MCP enabled)
      type = "http";
      url = "http://127.0.0.1:3845/mcp";
    };
  };

  mcpJson = builtins.toJSON { inherit mcpServers; };
  claudeSettingsJson = builtins.toJSON {
    inherit mcpServers;
    hooks = {
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "rtk hook claude";
            }
          ];
        }
      ];
    } // hooksCompiled.claude;
  };
  geminiSettingsJson = builtins.toJSON {
    inherit mcpServers;
    hooks = hooksCompiled.gemini;
  };

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
    ".claude/CLAUDE.md" = {
      text = claudeContent;
      force = true;
    };
    ".codex/AGENTS.md" = {
      text = codexContent;
      force = true;
    };
    ".gemini/GEMINI.md".text = instructions;

    ".claude/skills" = { source = skillsDir; force = true; };
    ".gemini/skills" = { source = skillsDir; force = true; };

    ".claude/agents" = { source = claudeAgentsDir; force = true; };
    ".gemini/agents" = { source = geminiAgentsDir; force = true; };

  } // {
    # NOTE: ~/.codex/config.toml is intentionally NOT managed here. Codex and
    # its plugins can mutate config.toml at runtime, which fails against a
    # read-only Nix store symlink. config.toml is therefore owned by codex; YOLO
    # defaults and base MCP servers are seeded once as a real file (see
    # codexToml below / docs). Re-seed manually if you change the shared
    # mcpServers list.
    ".codex/hooks.json" = {
      text = builtins.toJSON hooksCompiled.codex;
      force = true;
    };
    ".cursor/mcp.json".text = mcpJson;
    ".cursor/hooks.json" = {
      text = builtins.toJSON hooksCompiled.cursor;
      force = true;
    };
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
    install -m 600 ${pkgs.writeText "claude.json" claudeSettingsJson} "$target"
  '';

  home.activation.geminiSettingsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.gemini/settings.json"
    mkdir -p "$HOME/.gemini"
    rm -f "$target"
    install -m 600 ${pkgs.writeText "gemini-settings.json" geminiSettingsJson} "$target"
  '';
}
