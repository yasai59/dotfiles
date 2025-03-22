return {
	"catgoose/nvim-colorizer.lua",
	event = "BufReadPre",
	otps = {
		filetypes = "*",
	},
	config = function()
		require("colorizer").setup()
	end,
}
