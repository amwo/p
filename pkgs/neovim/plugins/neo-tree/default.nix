{ pkgs }:
{
  plugin = pkgs.vimPlugins.neo-tree-nvim;

  type = "lua";

  config = ''
    require("neo-tree").setup({
      enable_diagnostics = false,
      enable_git_status = false,
      window = {
        position = "left",
        width = 30,
      },
      default_component_configs = {
        indent = {
          padding = 0,
          with_markers = false,
          with_expanders = true,
          expander_collapsed = "+",
          expander_expanded = "-",
        },
        modified = {
          symbol = "",
        },
      },
      filesystem = {
        window = {
          mappings = {
            ["."] = "none",
            ["<C-h>"] = "set_root",
          },
        },
        renderers = {
          directory = {
            { "indent" },
            { "name", trailing_slash = true, use_git_status_colors = false },
          },
          file = {
            { "indent" },
            { "name", use_git_status_colors = false },
          },
        },
      },
    })

    local function toggle_neotree()
      vim.cmd("Neotree toggle")
    end

    vim.keymap.set("n", ".", toggle_neotree, { noremap = true, silent = true })
  '';
}
