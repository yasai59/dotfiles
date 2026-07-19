vim.cmd("let g:netrw_banner = 0")
-- editor numbers
vim.opt.nu = true
vim.opt.relativenumber = true
-- set tabs to 2 and make them spaces
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.wrap = false
-- persistent undo
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
-- search settings
vim.opt.incsearch = true
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- colors
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
-- backspace
vim.opt.backspace = { "start", "eol", "indent" }

vim.opt.splitright = true
vim.opt.splitbelow = true
-- clipboard sync with system
vim.opt.clipboard:append("unnamedplus")
vim.opt.isfname:append("@-@")

vim.opt.mouse = "a"
vim.g.editorconfig = true
-- yanking with visual feedback
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

-- show errors and warnings
vim.diagnostic.config({
  virtual_text = true,
  virtual_lines = false,
  signs = true,
  underline = true,
  severity_sort = true,
})
-- session options
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
