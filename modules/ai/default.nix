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

  skillsDir = "${dir}/skills";
  agentsDir = "${dir}/agents";
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
      command = "npx";
      args = [ "-y" "@storybook/addon-mcp" ];
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
  mcpToml = lib.concatStringsSep "\n" (
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
    ".codex/instructions.md".text = fullContent "codex";
    ".gemini/GEMINI.md".text = fullContent "gemini";

    ".claude/skills" = { source = skillsDir; force = true; };
    ".codex/skills" = { source = skillsDir; force = true; };
    ".gemini/skills" = { source = skillsDir; force = true; };

    ".claude/agents" = { source = agentsDir; force = true; };
    ".gemini/agents" = { source = agentsDir; force = true; };

  } // lib.optionalAttrs (dirExists rulesDir) {
    ".claude/rules" = { source = rulesDir; force = true; };
  } // {
    ".codex/config.toml" = {
      text = mcpToml;
      force = true;
    };
    ".gemini/settings.json".text = mcpJson;
    ".cursor/mcp.json".text = mcpJson;
  };

  home.activation.removeConflictingDirs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for dir in \
      "$HOME/.claude/skills" \
      "$HOME/.claude/agents" \
      "$HOME/.claude/rules" \
      "$HOME/.codex/skills" \
      "$HOME/.gemini/skills" \
      "$HOME/.gemini/agents"
    do
      if [ -d "$dir" ] && [ ! -L "$dir" ]; then
        rm -rf "$dir"
      fi
    done
  '';

  home.activation.claudeMcpConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.claude.json"
    rm -f "$target"
    install -m 600 ${pkgs.writeText "claude.json" mcpJson} "$target"
  '';
}
