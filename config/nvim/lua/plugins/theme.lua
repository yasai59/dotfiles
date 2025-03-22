return {
	{ "nvim-tree/nvim-web-devicons" },
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
		config = function()
			require("tokyonight").setup({
				transparent = true,
			})
			vim.cmd("colorscheme tokyonight-storm")
		end,
	},
}
