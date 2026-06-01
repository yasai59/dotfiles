return {
	"laytan/cloak.nvim",
	config = function()
		require("cloak").setup({
			enabled = true,
			cloak_character = "*",
			highlight_group = "Comment",
			cloak_length = 10, -- Provide a number if you want to hide the true length of the value.
			try_all_patterns = true,
			cloak_telescope = true,
			cloak_on_leave = false,
			patterns = {
				{
					file_pattern = ".env*",
					cloak_pattern = "=.+",
					replace = nil,
				},
			},
		})
	end,
}
