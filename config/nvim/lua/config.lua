-- GLOBALS
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.netrw_banner = 0
vim.g.netrw_list_hide = "^./"
vim.g.netrw_hide = 1
-- vim.g.netrw_liststyle  = 3

vim.g.netrw_rm_cmd = "trash-put"
vim.g.netrw_rmdir_cmd = "trash-put"
vim.g.netrw_rmf_cmd = "rm -f"

-- OPT
-- vim.opt.colorcolumn = "81,82,83"
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.swapfile = true

vim.o.mouse = "a" -- a = activate, "" = deactivate
vim.o.showmode = false

vim.o.number = true
vim.o.relativenumber = true
vim.o.scrolloff = 10

vim.o.tabstop = 2
vim.o.shiftwidth = 2

vim.o.clipboard = "unnamedplus"
vim.o.completeopt = "menuone,noselect"
vim.o.termguicolors = true

vim.o.breakindent = true
vim.o.undofile = true

vim.o.expandtab = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.hlsearch = true

vim.o.cmdheight = 1    -- 0 to merge with statusbar

vim.o.foldcolumn = "1" -- '0' is not bad
vim.o.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- CMD
vim.cmd.highlight({ "Error", "guibg=red" })
vim.cmd.highlight({ "VirtColumn", "guibg=WHITE" })
vim.cmd.highlight({ "SignColumn", "guibg=NONE" })
vim.cmd.highlight({ "BufferLineFill", "guibg=NONE" })
vim.cmd.highlight({ "FoldColumn", "guibg=NONE" })
vim.cmd.highlight({ "FoldColumn", "guibg=NONE" })
vim.cmd.highlight({ "ColorColumn ", "guibg=NONE" })
vim.cmd.highlight({ "Cursor", "cterm=bold guibg=white guifg=black" })
vim.cmd.highlight({ "ColorColumn", "guibg=WHITE" })

local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = "*",
})
