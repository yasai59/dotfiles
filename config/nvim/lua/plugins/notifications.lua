return {
	{
		"j-hui/fidget.nvim",
		opts = {},
	},
	{
		"rcarriga/nvim-notify",
		config = function()
			require("notify").setup({
				merge_duplicates = true,
			})
		end,
	},
}
