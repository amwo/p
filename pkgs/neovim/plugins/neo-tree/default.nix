{ pkgs }:
{
  plugin = pkgs.vimPlugins.neo-tree-nvim;

  type = "lua";

  config = ''
    require("neo-tree").setup({
      window = {
        position = "left",
        width = 35,
      },
      default_component_configs = {
        indent = {
          expander_collapsed = "",
          expander_expanded = "",
        },
      },
    })

    vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { noremap = true, silent = true })
  '';
}
