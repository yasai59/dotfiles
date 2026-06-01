return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lualine = require("lualine")
		lualine.setup({
			options = {
				icons_enabled = true,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				globalstatus = false,
				refresh = {
					statusline = 100,
					tabline = 1000,
					winbar = 1000,
				},
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff" },
				lualine_c = {
					-- {
					-- 	"macro-recording",
					-- 	fmt = function()
					-- 		local recording_register = vim.fn.reg_recording()
					-- 		if recording_register == "" then
					-- 			return ""
					-- 		else
					-- 			return "Recording @" .. recording_register
					-- 		end
					-- 	end,
					-- },
					{
						"diagnostics",
						sources = { "nvim_diagnostic" },

						-- Displays diagnostics for the defined severity types
						sections = { "error", "warn", "info", "hint" },
					},
				},
				lualine_x = { "location" },
				lualine_y = { "filename" },
				lualine_z = { "progress" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "diagnostics" },
				lualine_x = { "location" },
				lualine_y = { "filename" },
				lualine_z = { "progress" },
			},
			tabline = {},
			winbar = {},
			inactive_winbar = {},
			extensions = {},
		})

		vim.api.nvim_create_autocmd("RecordingEnter", {
			callback = function()
				lualine.refresh({
					place = { "statusline" },
				})
			end,
		})

		vim.api.nvim_create_autocmd("RecordingLeave", {
			callback = function()
				local timer = vim.uv.new_timer()
				if timer == nil then
					return
				end
				timer:start(
					50,
					0,
					vim.schedule_wrap(function()
						lualine.refresh({
							place = { "statusline" },
						})
					end)
				)
			end,
		})
	end,
}
