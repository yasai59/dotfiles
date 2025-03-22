return {
  "stevearc/conform.nvim",
  config = function()
    require("conform").setup({
      default_format_opts = {
        timeout_ms = 3000,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },
      formatters = {
        injected = { options = { ignore_errors = true } },
      },
      formatters_by_ft = {
        lua = { "stylua" },
        typescript = { "prettierd" },
        typescriptreact = { "prettierd" },
        javascript = { "prettierd" },
        javascriptreact = { "prettierd" },
        bash = { "shfmt" },
        css = { "prettierd" },
        java = { "astyle" },
        go = { "gofmt" },
        php = { "pint" },
        python = { "pyink" },
        rust = { "rustfmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        cs = { "csharpier" },
        html = { "prettierd" },
        json = { "prettierd" },
        jsonc = { "prettierd" },
        sh = { "shfmt" },
        toml = { "taplo" },
        yaml = { "yamlfmt" },
        tex = { "latexindent" },
        xml = { "xmlformatter" },
      },
    })
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function(args)
        require("conform").format({ bufnr = args.buf })
      end,
    })
    vim.opt.formatexpr = "v:lua.require('conform').formatexpr()"
  end,
}
