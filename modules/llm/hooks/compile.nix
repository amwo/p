{ lib, pkgs }:

# Compile the hook IR (../hooks.json) into each LLM's native hook config.
#
# Hook executables are built here, so `home-manager switch` compiles them at
# apply time and the emitted commands point at the resulting store paths. One
# source of truth -> Claude Code, Codex, Gemini CLI and Cursor configs.
#
# Per-target differences (verified June 2026):
#   - event name:  claude/codex PostToolUse, gemini AfterTool, cursor afterFileEdit
#   - edit matcher: differs by tool-name vocabulary; cursor has a native file event
#   - timeout unit: seconds, except gemini (milliseconds)
#   - cursor shape: flat per-event array, no nested `hooks`, no `type` field

let
  manifest = builtins.fromJSON (builtins.readFile ../hooks.json);

  # Build the hook executables (compiled at apply time). stdenv.cc provides the
  # linker rustc needs (gcc on Linux, clang on Darwin) since runCommandLocal uses
  # a stdenv without a C compiler by default.
  bins = pkgs.runCommandLocal "llm-hook-bins" { nativeBuildInputs = [ pkgs.rustc pkgs.stdenv.cc ]; } ''
    mkdir -p "$out/bin"
    rustc -O --edition 2021 ${./memory-organize.rs} -o "$out/bin/memory-organize"
    install -m 0755 ${./format-and-lint.sh} "$out/bin/format-and-lint"
  '';

  cmd = h: "${bins}/bin/${h.run.script}";

  # Current hooks all run "after a file edit". Select those targeting `target`.
  editHooks =
    target: lib.filter (h: (h.match.edit or false) && lib.elem target (h.targets or [ ])) manifest.hooks;

  # Tool-name matcher meaning "a file was edited", per target's tool vocabulary.
  editMatcher = {
    claude = "Edit|Write|MultiEdit";
    codex = "Edit|Write|apply_patch";
    gemini = "write_file|replace";
  };

  # Nested matcher-group shape shared by claude / codex / gemini.
  group = target: scaleTimeout: h: {
    matcher = editMatcher.${target};
    hooks = [
      ({ type = "command"; command = cmd h; }
        // lib.optionalAttrs (h ? timeout) { timeout = scaleTimeout h.timeout; })
    ];
  };

  seconds = t: t;
  millis = t: t * 1000;
in
{
  inherit bins;

  # Merge into ~/.claude/settings.json `hooks`.
  claude.PostToolUse = map (group "claude" seconds) (editHooks "claude");

  # Full ~/.codex/hooks.json document.
  codex.hooks.PostToolUse = map (group "codex" seconds) (editHooks "codex");

  # Merge into ~/.gemini/settings.json `hooks` (timeouts in milliseconds).
  gemini.AfterTool = map (group "gemini" millis) (editHooks "gemini");

  # Full ~/.cursor/hooks.json document (flat array, native file-edit event).
  cursor = {
    version = 1;
    hooks.afterFileEdit = map
      (h: { command = cmd h; } // lib.optionalAttrs (h ? timeout) { inherit (h) timeout; })
      (editHooks "cursor");
  };
}
