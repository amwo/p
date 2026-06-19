{ lib, pkgs }:

# Compile the hook IR (../hooks.json) into each LLM's native hook config at apply
# time. One source of truth -> Claude Code, Codex, Gemini CLI and Cursor.
#
# Per-target differences (verified June 2026):
#   - event name: claude/codex PostToolUse|Stop, gemini AfterTool, cursor afterFileEdit
#   - edit matcher: differs by tool-name vocabulary; cursor has a native file event
#   - timeout unit: seconds, except gemini (milliseconds)
#   - cursor shape: flat per-event array, no nested `hooks`, no `type` field

let
  manifest = builtins.fromJSON (builtins.readFile ../hooks.json);

  # Build the hook executables (compiled at apply time). stdenv.cc gives rustc a
  # linker (gcc on Linux, clang on Darwin); runCommandLocal omits a C compiler.
  bins =
    pkgs.runCommandLocal "llm-hook-bins"
      {
        nativeBuildInputs = [
          pkgs.rustc
          pkgs.stdenv.cc
        ];
      }
      ''
        mkdir -p "$out/bin"
        rustc -O --edition 2021 ${./memory-organize.rs} -o "$out/bin/memory-organize"
        install -m 0755 ${./format-and-lint.sh} "$out/bin/format-and-lint"
        install -m 0755 ${./loop-progress-guard.sh} "$out/bin/loop-progress-guard"
      '';

  cmd = h: "${bins}/bin/${h.run.script}";
  hooksFor = target: lib.filter (h: lib.elem target (h.targets or [ ])) manifest.hooks;

  editMatcher = {
    claude = "Edit|Write|MultiEdit";
    codex = "Edit|Write|apply_patch";
    gemini = "write_file|replace";
  };

  # canonical `on` -> per-target native event name (null = tool lacks the event)
  eventName =
    target: on:
    let
      m =
        {
          "post-tool" = {
            claude = "PostToolUse";
            codex = "PostToolUse";
            gemini = "AfterTool";
            cursor = "afterFileEdit";
          };
          "stop" = {
            claude = "Stop";
            codex = "Stop";
          };
        }
        .${on} or { };
    in
    m.${target} or null;

  seconds = t: t;
  millis = t: t * 1000;

  # nested {matcher?, hooks:[{type,command,timeout?}]} group (claude/codex/gemini).
  # Edit hooks carry a tool-name matcher; event hooks (stop) carry none.
  nestedGroup =
    target: scale: h:
    (lib.optionalAttrs (h.match.edit or false) { matcher = editMatcher.${target}; })
    // {
      hooks = [
        (
          {
            type = "command";
            command = cmd h;
          }
          // lib.optionalAttrs (h ? timeout) { timeout = scale h.timeout; }
        )
      ];
    };

  buildNested =
    target: scale:
    lib.foldl' (
      acc: h:
      let
        ev = eventName target h.on;
      in
      if ev == null then
        acc
      else
        acc // { ${ev} = (acc.${ev} or [ ]) ++ [ (nestedGroup target scale h) ]; }
    ) { } (hooksFor target);

  # cursor: flat per-event array, no `type`, native afterFileEdit (edit hooks only).
  cursorEntry = h: { command = cmd h; } // lib.optionalAttrs (h ? timeout) { inherit (h) timeout; };
  buildCursor = lib.foldl' (
    acc: h:
    let
      ev = eventName "cursor" h.on;
    in
    if ev == null then acc else acc // { ${ev} = (acc.${ev} or [ ]) ++ [ (cursorEntry h) ]; }
  ) { } (hooksFor "cursor");
in
{
  inherit bins;
  claude = buildNested "claude" seconds; # merge into ~/.claude/settings.json hooks
  codex.hooks = buildNested "codex" seconds; # full ~/.codex/hooks.json
  gemini = buildNested "gemini" millis; # merge into ~/.gemini/settings.json hooks (ms)
  cursor = {
    version = 1;
    hooks = buildCursor;
  }; # full ~/.cursor/hooks.json
}
