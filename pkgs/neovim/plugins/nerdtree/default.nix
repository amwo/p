{ pkgs }:
{
  plugin = pkgs.vimPlugins.nerdtree;

  type = "lua";

  config = ''
    vim.g.NERDTreeMinimalUI = 1
    vim.g.NERDTreeMinimalMenu = 1
    vim.g.NERDTreeOpenSplit = 'split'
    vim.g.NERDTreeReplacePromptOnOpen = 1
    vim.g.NERDTreeWinSize = 35
    vim.g.NERDTreeDirArrowCollapsible = ""
    vim.g.NERDTreeDirArrowExpandable = ""
    vim.keymap.set("n", "<leader>e", ":NERDTreeToggle<CR>", { noremap = true, silent = true })
  '';
}
