vim.g.mapleader		= " "
vim.g.maplocalleader	= " "

vim.opt.number		= true
vim.opt.relativenumber	= true

vim.opt.tabstop		= 2
vim.opt.shiftwidth	= 2

vim.opt.scrolloff	= 5

vim.opt.clipboard	= 'unnamedplus'

vim.opt.hlsearch	= true

local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = "*",
})
