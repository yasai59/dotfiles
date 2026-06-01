return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "artemave/workspace-diagnostics.nvim",
      {
        "folke/lazydev.nvim",
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
      {
        "dmmulroy/tsc.nvim",
        config = function()
          local tsc = require("tsc")
          tsc.setup({
            run_as_monorepo = true,
            use_diagnostics = true,
            auto_open_qflist = false,
            flags = {
              noEmit = true,
              watch = false,
            },
          })
        end,
      },
    },
    config = function()
      local servers = {
        "lua_ls",
        "vtsls",
        "gopls",
        "clangd",
        "fish_lsp",
        "tailwindcss",
        "astro",
      }

      vim.lsp.config("vtsls", {
        root_dir = function(fname)
          return require("lspconfig.util").root_pattern("tsconfig.json", ".git")(fname)
        end,
      })

      vim.lsp.enable(servers)

      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.HINT] = "",
            [vim.diagnostic.severity.INFO] = "",
          },
        },
      })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("nvim-lsp-attach", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          require("workspace-diagnostics").populate_workspace_diagnostics(client, event.buf)

          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          -- map("gd", vim.lsp.buf.definition, "[g]oto [d]efinition")
          -- map("gr", vim.lsp.buf.references, "[g]oto [r]eferences")
          -- map( "gi", vim.lsp.buf.implementation, "[g]oto [i]mplementation")
          -- map( "gt", vim.lsp.buf.type_definition, "[g]oto [t]ype Definition")
          map("gD", vim.lsp.buf.declaration, "[g]oto [D]eclaration")
          map("<leader>rn", vim.lsp.buf.rename, "[r]e[n]ame")
          map("<leader>ca", vim.lsp.buf.code_action, "[c]ode [a]ctions")
          map("K", vim.lsp.buf.hover, "Hover Documentation")
          map("<leader>tc", require("tsc").run, "[t]ype [c]heck")
        end,
      })
    end,
  },
}