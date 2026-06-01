return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  config = function()
    require("nvim-treesitter.config").setup({
      ensure_install = {"c", "lua", "vim", "vimdoc", "query", "rust"},
      auto_install = true,
      highlight = {
        enable = true,
      },
    })
  end,
}
