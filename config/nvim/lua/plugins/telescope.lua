return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = function()
      local builtin = require("telescope.builtin")
      local telescope = require("telescope")
      return {
        { "gd",               builtin.lsp_definitions,               desc = "[g]oto [d]efinitions" },
        { "gr",               builtin.lsp_references,                desc = "[g]oto [r]eferences" },
        { "gi",               builtin.lsp_implementations,           desc = "[g]oto [i]mplementations" },
        { "gt",               builtin.lsp_type_definitions,          desc = "[g]oto [t]ype definition" },
        { "<leader>pf",       builtin.find_files,                    desc = "[p]roject [f]iles" },
        { "<leader>pg",       builtin.live_grep,                     desc = "[p]roject live [g]rep" },
        { "<leader>ps",       builtin.grep_string,                   desc = "[p]roject grep [s]tring" },
        -- { "<leader>pe", builtin.diagnostics, desc = "[p]roject [e]rrors" },
        { "<leader>vk",       builtin.keymaps,                       desc = "[v]iew [k]eymaps" },
        { "<leader>vr",       builtin.oldfiles,                      desc = "[v]iew [r]ecent" },
        { "<leader>/",        builtin.current_buffer_fuzzy_find,     desc = "[/] Search in current buffer" },
        { "<leader><leader>", builtin.buffers,                       desc = "[ ] Find existing buffers" },
        { "<leader>fc",       telescope.extensions.flutter.commands, desc = "[f]lutter [c]ommands" }
      }
    end,
    config = function()
      local telescope = require("telescope")
      telescope.load_extension("flutter")
      local actions = require("telescope.actions")
      telescope.setup({
        defaults = {
          prompt_prefix = "   ",
          selection_caret = " ",
          entry_prefix = " ",
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.5,
            },
            width = 0.8,
            height = 0.8,
          },
          mappings = {
            n = { ["q"] = actions.close },
          },
          file_ignore_patterns = {},
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--ignore-file",
            ".gitignore",
          },
          borderchars = {
            prompt = { "─", " ", " ", " ", "─", "─", " ", " " },
            results = { " " },
            preview = { " " },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
        },
      })
    end,
  },
}
