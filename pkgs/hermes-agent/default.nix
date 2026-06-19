{ inputs, pkgs, ... }:

let
  localModel = "qwen2.5-coder-7b-instruct-q4_k_m";
  localBaseUrl = "http://127.0.0.1:8080/v1";
  localApiKey = "llama.cpp";
  localContextLength = 65536;
  hermesConfig = (pkgs.formats.yaml { }).generate "hermes-config.yaml" {
    model = {
      provider = "custom";
      default = localModel;
      base_url = localBaseUrl;
      api_key = localApiKey;
      api_mode = "chat_completions";
      context_length = localContextLength;
    };

    custom_providers = [
      {
        name = "llama.cpp local";
        base_url = localBaseUrl;
        api_key = localApiKey;
        api_mode = "chat_completions";
        model = localModel;
        context_length = localContextLength;
        models.${localModel}.context_length = localContextLength;
      }
    ];

    terminal = {
      backend = "local";
      cwd = ".";
      timeout = 180;
    };

    platform_toolsets.cli = [
      "web"
      "terminal"
      "file"
      "code_execution"
      "todo"
    ];

    agent.disabled_toolsets = [
      "browser"
      "vision"
      "video"
      "image_gen"
      "video_gen"
      "x_search"
      "moa"
      "tts"
      "skills"
      "memory"
      "context_engine"
      "session_search"
      "clarify"
      "delegation"
      "cronjob"
      "messaging"
      "homeassistant"
      "spotify"
      "discord"
      "discord_admin"
      "yuanbao"
      "computer_use"
    ];
  };
in

{
  home.packages = [
    inputs.hermes-agent.packages.${pkgs.system}.default
  ];

  home.file = {
    ".hermes/config.yaml" = {
      source = hermesConfig;
      force = true;
    };

    ".hermes/.env" = {
      text = ''
        OPENAI_API_KEY=${localApiKey}
      '';
      force = true;
    };
  };
}
