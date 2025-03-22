return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-context",
	},
	config = function()
		require("treesitter-context").setup({
			enable = true,
			max_lines = 2,
			min_window_height = 0,
			line_numbers = true,
			multiline_threshold = 20,
			trim_scope = "outer",
			mode = "cursor",
			separator = nil,
			zindex = 20,
		})
		require("nvim-treesitter.configs").setup({
            modules = {},
            ignore_install = {},
			ensure_installed = { "lua", "typescript" },
			sync_install = false,
			auto_install = true,
			highlight = {
				enable = true,
			},
		})
		vim.filetype.add({
			pattern = { [".*/hypr/.*%.conf"] = "hyprlang" },
		})
    end
}
