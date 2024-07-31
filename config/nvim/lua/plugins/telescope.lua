return {
    "nvim-telescope/telescope.nvim",
    version = "0.1.5",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    config = function()
        require("telescope").setup({
            pickers = {
                find_files = {
                    hidden = true
                }
            },
            defaults = {
                file_ignore_patterns = {
                    -- Common files
                    "/*.png",
                    "/*.jpg",
                    "/*.jpeg",
                    "/*.pdf",
                    "/*.ttf",
                    "/*.otf",
                    "/*.webp",
                    -- Projects
                    ".idea/*",
                    ".vscode/*",
                    ".vs/*",
                    "/*.vsconfig",
                    "/*.sln",
                    "node_modules/*",
                    ".git/*",
                },
            },
        })

        local builtin = require("telescope.builtin")

        local map = function(keys, func, desc)
            vim.keymap.set('n', "<leader>" .. keys, func, { desc = "Telescope: " .. desc })
        end

        map("/", builtin.current_buffer_fuzzy_find, '[/] Search in current buffer')
        map("pf", builtin.find_files, "[P]roject [F]iles")
        map("ps", builtin.live_grep, "[P]roject [S]tring")
        map("pw", function()
            local word = vim.fn.expand("<cword>");
            builtin.grep_string({ search = word })
        end, "[P]roject [W]ord")
        map("pe", builtin.diagnostics, "[P]roject [E]rrors (diagnostics)")
        map("vk", builtin.keymaps, "[V]iew [K]eymaps")
        map("vr", builtin.oldfiles, '[V]iew [R]ecent')
        map("<leader>", builtin.buffers, "[ ] Find existing buffers")
    end
}
