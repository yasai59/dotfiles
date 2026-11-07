return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "nvim-java/nvim-java"
  },
  config = function()
    local servers = {
      "lua_ls",
      "clangd",
      "astro",
      "hls",
      -- "deno",
      "ts_ls",
      "rust_analyzer",
      "tailwindcss",
      "jdtls"
    }

    for _, server in ipairs(servers) do
      vim.lsp.enable(server)
    end

    vim.lsp.config("emmet_language_server", {
      filetypes = {
        "css",
        "html",
        "javascript",
        "javascriptreact",
        "less",
        "sass",
        "scss",
        "pug",
        "typescriptreact",
      },
    })
    
    vim.lsp.enable("emmet_language_server")
  end,
}
