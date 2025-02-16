return {
	'rmagatti/auto-session',
	requires = {
		'nvim-telescope/telescope.nvim',
	},
	config = function()
		require("auto-session").setup {
			log_level = vim.log.levels.ERROR,
			auto_session_use_git_branch = false,
			auto_session_enable_last_session = false,
			session_lens = {
				buftypes_to_ignore = {},
				load_on_setup = true,
				theme_conf = { border = true },
				previewer = false,
			},
		}
		vim.keymap.set("n", "<C-s>", require("auto-session.session-lens").search_session, {
			noremap = true,
		})
	end
}
