return {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = {
                "nvim-lua/plenary.nvim",
        },
        keys = function()
                local harpoon = require("harpoon")
                return {
                        {
                                "<leader>M",
                                function()
                                        harpoon.ui:toggle_quick_menu(harpoon:list())
                                end,
                                desc = "Harpoon [M]arks",
                        },
                        {
                                "<leader>m",
                                function()
                                        harpoon:list():add()
                                end,
                                desc = "Harpoon [m]ark file",
                        },
                        {
                                "<A-f>",
                                function()
                                        harpoon:list():select(1)
                                end,
                                desc = "Harpoon mark 1",
                        },
                        {
                                "<A-d>",
                                function()
                                        harpoon:list():select(2)
                                end,
                                desc = "Harpoon mark 2",
                        },
                        {
                                "<A-s>",
                                function()
                                        harpoon:list():select(3)
                                end,
                                desc = "Harpoon mark 3",
                        },
                        {
                                "<A-a>",
                                function()
                                        harpoon:list():select(4)
                                end,
                                desc = "Harpoon mark 4",
                        },
                }
        end,
        config = function()
                require("harpoon"):setup({
                        settings = {
                                save_on_toggle = true,
                                save_on_change = true,
                        },
                })
        end,
}
