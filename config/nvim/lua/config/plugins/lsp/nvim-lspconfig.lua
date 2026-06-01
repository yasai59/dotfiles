return {
  "neovim/nvim-lspconfig",
  event = {"BufReadPre", "BufNewFile"},
  config = function()
    local servers = {
      "lua_ls",
      "clangd",
    }
    vim.lsp.enable(servers)
  end,
}
