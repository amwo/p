{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    syntaxHighlighting.enable = false;

    defaultKeymap = "emacs"; 
    
    shellAliases = {
      home = "nix run .";
      c = "cargo";
      gl = "git log --oneline";
      gs = "git status";
      ll = "ls -l";
      m = "make";
      t = "tmux -u";
      v = "nvim";
    };

    history = {
      size = 10000;
      save = 100;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      share = true;
      extended = true;
    };

    initContent = ''
      autoload -U compinit && compinit
      autoload -Uz vcs_info

      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      zstyle ':vcs_info:*' enable git
      zstyle ':vcs_info:git:*' formats '%b'
      zstyle ':vcs_info:git:*' actionformats '%b|%a'

      precmd() {
        vcs_info

        local head

        if [[ "$PWD" = "$HOME" ]]; then
          head="$USER"
        else
          head="$(basename "$PWD")"
        fi

        local branch="$vcs_info_msg_0_"

        if [[ -n "$branch" ]]; then
          PROMPT="$head%F{242} ($branch)%f ~ "
        else
          PROMPT="$head ~ "
        fi

        if [ -e "$HOME/.nix-profile/bin/zsh" ]; then
          export SHELL="$HOME/.nix-profile/bin/zsh"
        fi
      }

      setopt prompt_percent
      setopt prompt_subst
    '';
  };
}
