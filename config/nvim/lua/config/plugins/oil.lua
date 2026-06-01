return {
  "stevearc/oil.nvim",
  -- enabled = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("oil").setup({
      default_file_explorer = true,
      columns = {
        "icon",
        "size",
      },
      keymaps = {
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-c>"] = false,
        ["<C-r>"] = "actions.refresh",
        ["<M-h>"] = "actions.select_split",
        ["q"] = "actions.close",
        ["-"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
      },
      delete_to_trash = true,
      view_options = {
        show_hidden = true,
      },
      skip_confirm_for_simple_edits = true,
    })

    -- opens parent dir over current active window
    vim.keymap.set("n", "<leader>pv", "<CMD>Oil<CR>", { desc = "Open parent directory" })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "oil", -- Adjust if Oil uses a specific file type identifier
      callback = function()
        vim.opt_local.cursorline = true
      end,
    })
  end,

}
