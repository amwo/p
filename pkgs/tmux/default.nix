{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    escapeTime = 0;
    prefix = "C-z";

    extraConfig = ''
      unbind C-b

      set -g default-terminal "tmux-256color"
      set -as terminal-overrides ",*:Tc"
      set -g mouse on

      bind m split-window -vc "#{pane_current_path}"
      bind enter split-window -hc "#{pane_current_path}"
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R
      bind Space copy-mode
      bind z source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
      
      set -g pane-active-border-style fg=colour111,bg=colour233
      set -g pane-border-style fg=colour111,bg=colour233
      set -g status-bg black
      set -g status-fg white
      set -g status-justify centre
      
      set-option -g base-index 1
      set-option -g bell-action none
      
      set -g status-left " #[fg=colour242](#H)#[default] "
      set -g status-right ""
      set -g window-status-format "#[bg=black,fg=colour240]―――"
      set -g window-status-current-format "#[bg=black,fg=colour255]―――"
      
      set -g pane-active-border-style fg=white,bg=black
      set -g pane-border-style fg=white,bg=black
    '';
  };
}
