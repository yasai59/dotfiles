return {
	"stevearc/oil.nvim",
	config = function()
		vim.keymap.set("n", "<leader>pv", "<cmd>Oil<CR>", { desc = "[P]roject [N]etrw" })
		require("oil").setup({
			default_file_explorer = true,
			columns = {
				"icon",
				-- "permissions",
				-- "size",
				-- "mtime",
			},
			delete_to_trash = true,
			keymaps = {
				["g?"] = { "actions.show_help", mode = "n" },
				["<CR>"] = "actions.select",
				["gs"] = { "actions.change_sort", mode = "n" },
				["g."] = { "actions.toggle_hidden", mode = "n" },
			},
			use_default_keymaps = true,
			skip_confirm_for_simple_edits = true,
			view_options = {
				show_hidden = true,
				is_hidden_file = function(name, _)
					local m = name:match("^%.")
					return m ~= nil
				end,
				natural_order = "fast",
				case_insensitive = false,
				sort = {
					{ "type", "asc" },
					{ "name", "asc" },
				},
			},
		})
	end,
}
