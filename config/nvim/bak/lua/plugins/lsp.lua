return {
    "williamboman/mason.nvim",
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig",
        "VidocqH/lsp-lens.nvim",
				"hrsh7th/cmp-nvim-lsp",
    },
    config = function()
        local lspconfig = require("lspconfig")
        local capabilities = require('cmp_nvim_lsp').default_capabilities();
        capabilities.textDocument.foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true
        }
        require("mason").setup()
        require("mason-lspconfig").setup({
            ensure_installed = {
                "lua_ls",
            },
            automatic_installation = true,
            handlers = {
                function(server_name)
                    lspconfig[server_name].setup({
                        capabilities = capabilities
                    })
                end,
                ["lua_ls"] = function()
                    lspconfig.lua_ls.setup({
                        capabilities = capabilities,
                        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
                    })
                end
            }
        })

        local SymbolKind = vim.lsp.protocol.SymbolKind

        require('lsp-lens').setup({
            enable = true,
            include_declaration = false, -- Reference include declaration
            sections = {                 -- Enable / Disable specific request, formatter example looks 'Format Requests'
                definition = false,
                references = false,
                implements = true,
                git_authors = false,
            },
            ignore_filetype = {
                "prisma",
            },
            -- Target Symbol Kinds to show lens information
            target_symbol_kinds = { SymbolKind.Function, SymbolKind.Method, SymbolKind.Interface },
            -- Symbol Kinds that may have target symbol kinds as children
            wrapper_symbol_kinds = { SymbolKind.Class, SymbolKind.Struct },
        })

        vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
            callback = function(event)
                local builtin = require('telescope.builtin')
                local map = function(keys, func, desc)
                    vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
                end
                map('gd', builtin.lsp_definitions, '[G]oto [D]efinition')
                map('gr', builtin.lsp_references, '[G]oto [R]eferences')
                map('gi', builtin.lsp_implementations, '[G]oto [I]mplementation')
                map('gt', builtin.lsp_type_definitions, '[G]oto [T]ype Definition')
                --map('<leader>ds', builtin.lsp_document_symbols, '[D]ocument [S]ymbols')
                --map('<leader>ws', builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
                map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
                map('<A-return>', vim.lsp.buf.code_action, '[C]ode [A]ction')
                map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
                map('K', vim.lsp.buf.hover, 'Hover Documentation')
            end
        })
    end
}
