{ pkgs, ... }:

let
  llamaBin = "/home/am/Projects/llama/bin";
  defaultModel = "/data/llama/models/qwen2.5-coder-7b-instruct/qwen2.5-coder-7b-instruct-q4_k_m.gguf";
in

{
  home.packages = [
    (pkgs.writeShellScriptBin "llama" ''
      has_model=0
      for arg in "$@"; do
        case "$arg" in
          -h|--help|--version|-v)
            exec "${llamaBin}/llama-cli" "$@"
            ;;
          -m|--model|--model=*)
            has_model=1
            break
            ;;
        esac
      done

      if [ "$has_model" -eq 1 ]; then
        exec "${llamaBin}/llama-cli" "$@"
      fi

      exec "${llamaBin}/llama-cli" --model "${defaultModel}" "$@"
    '')
  ];
}
