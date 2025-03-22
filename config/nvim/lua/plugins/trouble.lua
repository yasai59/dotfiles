return {
	"folke/trouble.nvim",
	opts = {
		modes = {
			lsp = {
				win = { position = "right" },
			},
		},
	},
	cmd = "Trouble",
	lazy = false,
	keys = {
		{
			"<leader>pe",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
		},
		{
			"<leader>fe",
			"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
			desc = "Buffer Diagnostics (Trouble)",
		},
		{
			"<leader>qe",
			"<cmd>Trouble qflist toggle<cr>",
			desc = "Quickfix List (Trouble)",
		},
	},
}
