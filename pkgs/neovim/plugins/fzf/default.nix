{ pkgs }:
{
  plugin = pkgs.vimPlugins.fzf-vim;

  type = "lua";

  config = ''
    vim.g.fzf_layout = { down = '33%' }

    -- Project-wide full-text search (live ripgrep). Package-manager and build
    -- output directories are excluded so huge files never enter the search.
    local rg = table.concat({
      "rg --column --line-number --no-heading --color=always --smart-case --hidden",
      "--glob '!**/.git/**'",
      "--glob '!**/node_modules/**'",
      "--glob '!**/.next/**'",
      "--glob '!**/dist/**'",
      "--glob '!**/build/**'",
      "--glob '!**/target/**'",
      "--glob '!**/vendor/**'",
      "--glob '!**/.venv/**'",
      "--glob '!**/__pycache__/**'",
      "--glob '!**/*.lock'",
      "--glob '!**/*-lock.json'",
    }, " ")

    vim.api.nvim_create_user_command("ProjectGrep", function(arg)
      local fmt = rg .. " -- %s || true"
      local initial = string.format(fmt, vim.fn.shellescape(arg.args))
      local reload = string.format(fmt, "{q}")
      local spec = {
        options = { "--disabled", "--query", arg.args, "--bind", "change:reload:" .. reload },
      }
      vim.fn["fzf#vim#grep"](initial, spec, arg.bang)
    end, { nargs = "*", bang = true })
  '';
}
