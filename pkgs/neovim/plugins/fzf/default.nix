{ pkgs }:
{
  plugin = pkgs.vimPlugins.fzf-vim;

  type = "lua";

  config = ''
    vim.g.fzf_layout = { down = '33%' }
  '';
}
