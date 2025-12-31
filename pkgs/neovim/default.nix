{ pkgs, ... }:

let
  plugins = import ./plugins { inherit pkgs; };
  am = ./color/am.lua;
in
{
  programs.neovim = {
    enable = true;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    plugins = plugins;

    extraPackages = [
      pkgs.nodePackages.typescript
      pkgs.nodePackages.typescript-language-server
      pkgs.nodePackages.vscode-langservers-extracted
      pkgs.rust-analyzer
    ];

    extraLuaConfig = ''
      vim.g.mapleader = " "

      vim.o.clipboard = "unnamedplus"
      vim.o.expandtab = true
      vim.o.ignorecase = true
      vim.o.shiftwidth = 2
      vim.o.smartcase = true
      vim.o.tabstop = 2
      vim.o.termguicolors = true
      vim.o.wrap = false
      vim.o.mouse = "a"
      vim.o.swapfile = false
      vim.o.backup = false
      vim.o.updatetime = 200
      vim.o.signcolumn = "no"

      local diagnostic_ns = vim.api.nvim_create_namespace("am/diagnostic_range")

      local function diagnostic_hl(severity)
        local levels = vim.diagnostic.severity
        if severity == levels.ERROR then
          return "DiagnosticError"
        elseif severity == levels.WARN then
          return "DiagnosticWarn"
        elseif severity == levels.INFO then
          return "DiagnosticInfo"
        elseif severity == levels.HINT then
          return "DiagnosticHint"
        end
      end

      vim.diagnostic.handlers["am/range_highlight"] = {
        show = function(_, bufnr, diagnostics, _)
          vim.api.nvim_buf_clear_namespace(bufnr, diagnostic_ns, 0, -1)
          local line_count = vim.api.nvim_buf_line_count(bufnr)
          if line_count == 0 then
            return
          end
          local max_row = line_count - 1
          for _, diagnostic in ipairs(diagnostics) do
            local hl = diagnostic_hl(diagnostic.severity)
            if hl then
              local start_row = math.min(diagnostic.lnum, max_row)
              local end_row = math.min(diagnostic.end_lnum or diagnostic.lnum, max_row)
              if end_row < start_row then
                end_row = start_row
              end

              local start_col = diagnostic.col
              local end_col = diagnostic.end_col or (start_col + 1)
              if end_row == start_row then
                local line = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, false)[1] or ""
                local max_col = #line
                if end_col <= start_col then
                  end_col = start_col + 1
                end
                if end_col > max_col then
                  end_col = max_col
                end
                if end_col <= start_col then
                  goto continue
                end
              end

              vim.api.nvim_buf_set_extmark(bufnr, diagnostic_ns, start_row, start_col, {
                end_row = end_row,
                end_col = end_col,
                hl_group = hl,
              })
            end
            ::continue::
          end
        end,
        hide = function(_, bufnr)
          vim.api.nvim_buf_clear_namespace(bufnr, diagnostic_ns, 0, -1)
        end,
      }

      vim.diagnostic.config({
        update_in_insert = true,
        signs = false,
        underline = false,
        ["am/range_highlight"] = {},
      })

      local function statusline_effective_colors()
        local status_hl = vim.api.nvim_get_hl(0, { name = "StatusLine", link = true }) or {}
        local fg = vim.fn.synIDattr(vim.fn.hlID("StatusLine"), "fg#")
        local bg = vim.fn.synIDattr(vim.fn.hlID("StatusLine"), "bg#")
        local ctermfg = vim.fn.synIDattr(vim.fn.hlID("StatusLine"), "fg", "cterm")
        local ctermbg = vim.fn.synIDattr(vim.fn.hlID("StatusLine"), "bg", "cterm")
        local reverse = vim.fn.synIDattr(vim.fn.hlID("StatusLine"), "reverse") == "1"

        if fg == "" then
          fg = status_hl.fg
        end
        if bg == "" then
          bg = status_hl.bg
        end
        if ctermfg == "" then
          ctermfg = status_hl.ctermfg
        end
        if ctermbg == "" then
          ctermbg = status_hl.ctermbg
        end
        if reverse then
          fg, bg = bg, fg
          ctermfg, ctermbg = ctermbg, ctermfg
        end
        return { fg = fg, bg = bg, ctermfg = ctermfg, ctermbg = ctermbg }
      end

      local function set_diagnostic_statusline_hl()
        local status = statusline_effective_colors()
        local fallback = {
          DiagnosticError = { fg = "#ff5555", ctermfg = 9 },
          DiagnosticWarn = { fg = "#f1fa8c", ctermfg = 11 },
          DiagnosticInfo = { fg = "#8be9fd", ctermfg = 14 },
          DiagnosticHint = { fg = "#50fa7b", ctermfg = 10 },
        }
        local groups = {
          { name = "amStatusDiagError", src = "DiagnosticError" },
          { name = "amStatusDiagWarn", src = "DiagnosticWarn" },
          { name = "amStatusDiagInfo", src = "DiagnosticInfo" },
          { name = "amStatusDiagHint", src = "DiagnosticHint" },
        }

        for _, item in ipairs(groups) do
          local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = item.src, link = true })
          local fg = ok and hl and hl.fg or nil
          local ctermfg = ok and hl and hl.ctermfg or nil
          if not fg and not ctermfg then
            fg = fallback[item.src].fg
            ctermfg = fallback[item.src].ctermfg
          end
          vim.api.nvim_set_hl(0, item.name, {
            fg = fg,
            ctermfg = ctermfg,
            bg = status.bg,
            ctermbg = status.ctermbg,
            reverse = false,
            nocombine = true,
          })
        end
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_diagnostic_statusline_hl,
      })

      local function diag_count(severity_name)
        local severity = vim.diagnostic.severity[severity_name]
        if not severity then
          return 0
        end
        return #vim.diagnostic.get(0, { severity = severity })
      end

      local function diag_segment(label, severity_name)
        local count = diag_count(severity_name)
        if count == 0 then
          return ""
        end
        return string.format("%s:%d ", label, count)
      end

      _G.am_diag_segment = diag_segment
      vim.api.nvim_create_autocmd("DiagnosticChanged", {
        callback = function()
          vim.cmd("redrawstatus")
        end,
      })
      local statusline = vim.o.statusline
      if not statusline:find("am_diag_segment", 1, true) then
        local addon = table.concat({
          "%#amStatusDiagError#%{v:lua.am_diag_segment('E','ERROR')}",
          "%#amStatusDiagWarn#%{v:lua.am_diag_segment('W','WARN')}",
          "%#amStatusDiagInfo#%{v:lua.am_diag_segment('I','INFO')}",
          "%#amStatusDiagHint#%{v:lua.am_diag_segment('H','HINT')}",
          "%#StatusLine#",
        }, "")
        if statusline == "" then
          vim.o.statusline = "%=" .. addon
        elseif statusline:find("%=", 1, true) then
          vim.o.statusline = statusline .. " " .. addon
        else
          vim.o.statusline = statusline .. " %=" .. addon
        end
      end

      local lsp = vim.lsp

      lsp.config("*", {
        capabilities = lsp.protocol.make_client_capabilities(),
      })

      lsp.config.ts_ls = {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
      }

      lsp.config.eslint = {
        cmd = { "vscode-eslint-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        root_markers = {
          "eslint.config.js",
          "eslint.config.mjs",
          ".eslintrc",
          ".eslintrc.js",
          ".eslintrc.cjs",
          ".eslintrc.json",
          ".eslintrc.yaml",
          ".eslintrc.yml",
          "package.json",
        },
      }

      lsp.config.rust_analyzer = {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        root_markers = { "Cargo.toml", "rust-project.json", ".git" },
        settings = {
          ["rust-analyzer"] = {
            check = {
              command = "clippy",
            },
          },
        },
      }

      lsp.enable({ "ts_ls", "eslint", "rust_analyzer" })

      dofile("${am}")

      set_diagnostic_statusline_hl()

      vim.api.nvim_create_autocmd("CursorHold", {
        callback = function()
          vim.diagnostic.open_float(nil, {
            focusable = false,
            scope = "cursor",
            border = "rounded",
          })
        end,
      })

      vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#ffffff", bg = "#181818" })
      vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#ffffff", bg = "#181818" })

      local keymaps = {
        { "n", "<C-a>", "0" },
        { "n", "<C-e>", "$" },
        { "n", "<C-j>", function() vim.lsp.buf.definition() end },
        { "n", "<C-]>", function() vim.diagnostic.goto_next({ wrap = true, float = false }) end },
        { "n", "<esc><esc>", ":nohl<CR>" },
        { "n", "<leader>d", ":bdelete<CR>" },
        { "n", "<leader>f", ":FZF<CR>" },
        { "n", "<leader>n", ":bnext<CR>" },
        { "n", "<leader>p", ":bprevious<CR>" },
        { "n", "<leader>q", ":q<CR>" },
        { "n", "<leader>w", ":w<CR>" },
        { "n", "j", "gj" },
        { "n", "k", "gk" },
      }

      for _, keymap in ipairs(keymaps) do
        local mode = keymap[1]
        local lhs = keymap[2]
        local rhs = keymap[3]
        local opts = keymap[4] or { noremap = true, silent = true }
        
        vim.keymap.set(mode, lhs, rhs, opts)
      end
    '';
  };
}
