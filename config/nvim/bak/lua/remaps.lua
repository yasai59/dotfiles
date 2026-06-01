-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("n", "<leader>n", "<cmd>cnext<CR>zz", { desc = "Forward quickfix list" })
vim.keymap.set("n", "<leader>N", "<cmd>cprev<CR>zz", { desc = "Backward quickfix list" })
-- Location list
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Backward location list" })
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Forward location list" })

vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "[p]aste without copying" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "[d]elete without copying" })

-- Increment
vim.keymap.set("n", "+", "<C-a>")
vim.keymap.set("n", "-", "<C-x>")

-- Seelect all
-- key.set("n", "<C-a>", "gg<S-v>G")

-- FUN

-- Ctrl-C exit insert
vim.keymap.set("i", "<C-c>", "<Esc>")

vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
vim.keymap.set("n", "Q", "<nop>")

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { desc = "Cmod [x] current file" })

--QOL
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("i", "<D-Space>", "")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
-- Disable arrow keys
vim.keymap.set("n", "<left>", "<cmd>echo 'Use h to move!!'<CR>")
vim.keymap.set("n", "<right>", "<cmd>echo 'Use l to move!!'<CR>")
vim.keymap.set("n", "<up>", "<cmd>echo 'Use k to move!!'<CR>")
vim.keymap.set("n", "<down>", "<cmd>echo 'Use j to move!!'<CR>")
