return {
    "stevearc/conform.nvim",
    config = function()
        local conform = require("conform")
        conform.setup({
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "isort", "black" },
                javascript = { "deno" },
                typescript = { "deno" },
                bash = { "beautysh" },
                css = { "stylelint" },
                java = { "astyle" },
                go = { "gofmt" },
                php = { "pint" },
                c = { "clang-format" },
                cs = { "csharpier" },
                html = { "htmlbeautifier" }
            },
            format_on_save = {
                timeout_ms = 500,
                lsp_fallback = true,
            }
        })

        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*",
            callback = function(args)
                conform.format({ bufnr = args.buf })
            end,
        })

        vim.opt.formatexpr = "v:lua.require'conform'.formatexpr()"
    end
}
