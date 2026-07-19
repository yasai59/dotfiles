return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local servers = {
      "lua_ls",
      "clangd",
      "astro",
      "deno",
      "rust_analyzer",
    }
    vim.lsp.enable(servers)
  end,
}
