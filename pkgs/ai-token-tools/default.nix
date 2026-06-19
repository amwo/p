{ pkgs, ... }:

let
  toonVersion = "2.3.0";
  rtkAgentGuide = ''
    # RTK - Rust Token Killer

    **Usage**: Token-optimized CLI proxy for shell commands.

    ## Rule

    Always prefix shell commands with `rtk`.

    Examples:

    ```bash
    rtk git status
    rtk cargo test
    rtk npm run build
    rtk pytest -q
    ```

    ## Meta Commands

    ```bash
    rtk gain            # Token savings analytics
    rtk gain --history  # Recent command savings history
    rtk proxy <cmd>     # Run raw command without filtering
    ```

    ## Verification

    ```bash
    rtk --version
    rtk gain
    which rtk
    ```
  '';
in
{
  home.packages = [
    pkgs.rtk
    (pkgs.writeShellScriptBin "toon" ''
      exec ${pkgs.nodejs_latest}/bin/npx --yes @toon-format/cli@${toonVersion} "$@"
    '')
  ];

  home.file = {
    ".codex/RTK.md" = {
      text = rtkAgentGuide;
      force = true;
    };

    ".claude/RTK.md" = {
      text = rtkAgentGuide;
      force = true;
    };
  };
}
