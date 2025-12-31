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
      bind v split-window -vc "#{pane_current_path}"
      bind enter split-window -hc "#{pane_current_path}"
      bind -n M-Enter split-window -vc "#{pane_current_path}"
      bind -n M-S-Enter split-window -hc "#{pane_current_path}"
      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R
      bind -n C-Left select-pane -L
      bind -n C-Down select-pane -D
      bind -n C-Up select-pane -U
      bind -n C-Right select-pane -R
      bind -n C-S-Left resize-pane -L 5
      bind -n C-S-Down resize-pane -D 5
      bind -n C-S-Up resize-pane -U 5
      bind -n C-S-Right resize-pane -R 5
      bind Space copy-mode
      bind z source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"


      set-option -g base-index 1
      set-option -g bell-action none

      set -g status-justify centre
      set -g status-left " #[fg=colour242](#H)#[default] "
      set -g status-right ""
      set -g window-status-format "#[bg=#111111,fg=colour240]―――"
      set -g window-status-current-format "#[bg=#111111,fg=colour255]―――"
      set -g status-style "bg=#111111,fg=white"
      set -g status off

      set -g window-style 'fg=colour245,bg=#111111'
      set -g window-active-style 'fg=white,bg=#111111'
      set -g pane-border-style "fg=#191919,bg=#111111"
      set -g pane-active-border-style "fg=#191919,bg=#111111"
    '';
  };
}
