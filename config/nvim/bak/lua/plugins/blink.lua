return {
	"saghen/blink.cmp",
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	version = "*",
	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		completion = {
			ghost_text = {
				enabled = false,
			},
			accept = {
				auto_brackets = {
					enabled = false,
				},
				create_undo_point = true,
			},
			documentation = {
				auto_show = true,
			},
		},
		sources = {
			default = { "lazydev", "lsp", "path", "snippets", "buffer" },
			providers = {
				lsp = {
					name = "LSP",
					module = "blink.cmp.sources.lsp",
					score_offset = 100,
				},
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 100,
				},
			},
		},
		keymap = {
			preset = "default",
			["<Tab>"] = { "accept", "fallback" },
			["<C-j>"] = { "select_next", "fallback" },
			["<C-k>"] = { "select_prev", "fallback" },
			["<C-b>"] = { "scroll_documentation_down", "fallback" },
			["<C-f>"] = { "scroll_documentation_up", "fallback" },
			["<C-Space>"] = {
				"show",
				"show_documentation",
				"hide_documentation",
			},
		},
		appearance = {
			use_nvim_cmp_as_default = true,
			nerd_font_variant = "mono",
		},
		signature = { enabled = true },
	},
}
