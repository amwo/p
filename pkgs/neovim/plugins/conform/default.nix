{ pkgs }:
{
  plugin = pkgs.vimPlugins.conform-nvim;

  type = "lua";

  config = ''
    require("conform").setup({
      formatters_by_ft = {
        nix = { "nixfmt" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        toml = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        rust = { "rustfmt" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },
    })
  '';
}
