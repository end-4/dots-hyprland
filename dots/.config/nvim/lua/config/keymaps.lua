-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

keymap.set("i", "<C-c>", "<Esc>", { noremap = true, silent = true })

keymap.set("n", "H", "^")
keymap.set("n", "L", "$")
keymap.set("v", "H", "^")
keymap.set("v", "L", "$")

keymap.set("n", "<A-h>", ":bprevious<CR>", { noremap = true, silent = true })
keymap.set("n", "<A-l>", ":bnext<CR>", { noremap = true, silent = true })

-- keymap.set("n", "+", "<C-a>")
-- keymap.set("n", "-", "<C-x>")
keymap.set({ "n", "v" }, "<C-a>", "<Nop>", { desc = "Disable default increment" })
keymap.set({ "n", "v" }, "<C-x>", "<Nop>", { desc = "Disable default decrement" })

keymap.set("n", "Q", ":bdelete<CR>", { noremap = true, silent = true })

-- Copy/Paste
keymap.set("v", "y", '"+y')

keymap.set("n", "<C-z>", "", { noremap = true, silent = true })

-- Shift-Enter --
keymap.set("i", "<S-Enter>", "<Esc>o", opts)
keymap.set("i", "<C-Enter>", "<Esc>O", opts)
keymap.set("n", "<S-Enter>", "o", opts)
keymap.set("n", "<C-Enter>", "O", opts)
-- vim.keymap.set('n', '<Esc>[13;2u', 'o', { noremap = true, silent = true })
-- vim.keymap.set('n', '<Esc>[13;5u', 'O', { noremap = true, silent = true })

-- Select all
keymap.set("n", "<C-a>", "gg<S-v>G")
-- keymap.set("i", "<C-a>", "<Esc>gg<S-v>G")

-- Text Editing
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")
keymap.set("v", "<", "<gv")
keymap.set("v", ">", ">gv")

-- Lsp
keymap.set("n", "<leader>gd", ":lua vim.lsp.buf.definition()<CR>")
keymap.set("n", "<leader>gi", ":lua vim.lsp.buf.implementation()<CR>")
keymap.set("n", "K", ":lua vim.lsp.buf.hover()<CR>")
keymap.set("n", "<leader>rn", ":lua vim.lsp.buf.rename()<CR>")
keymap.set("n", "<leader>gr", ":lua vim.lsp.buf.references()<CR>")

-- remove but don't copy to clipboard
keymap.set("v", "x", '"_x', opts)
keymap.set("n", "dd", '"_dd', opts)
keymap.set("v", "c", '"_c', opts)
keymap.set("n", "cc", '"_cc', opts)

-- Duplication
-- keymap.set("v", "<C-d>", "<Esc>yyPi")

-- Quit
-- keymap.set("i", "<c-q>", "<esc><c-z>")
-- keymap.set("n", "<c-q>", "<c-z>")
keymap.set("n", "<Leader>w", ":update<Return>")
keymap.set("n", "<Leader>q", ":quit<Return>")
keymap.set("n", "<Leader>Q", ":qa<Return>")

-- Delete a word backwards
keymap.set("n", "dw", "vb_d")

-- Copy/Paste
-- keymap.set("v", "<C-S-c>", "y", opts)

-- New tab
keymap.set("n", "te", ":tabedit", opts)
keymap.set("n", "<tab>", ":tabnext<Return>", opts)
keymap.set("n", "<s-tab>", ":tabprev<Return>", opts)
keymap.set("n", "tw", ":tabclose<Return>", opts)

-- Split window
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)
-- Move window
keymap.set("n", "sh", "<C-w>h")
keymap.set("n", "sk", "<C-w>k")
keymap.set("n", "sj", "<C-w>j")
keymap.set("n", "sl", "<C-w>l")

-- Resize window
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")

-- Undo
-- keymap.set('n', '<C-z>', 'u')
-- keymap.set('i', '<C-z>', '<Esc>ui')

-- Run python
-- keymap.set("n", "<leader>R", ":!python3 %<Return>", opts)
keymap.set("n", "<leader>rr", ":RunCode<CR>", { noremap = true, silent = true })
-- -- Redo
-- keymap.set('n', '<C-S-Z', 'C-r')
-- keymap.set('i', '<C-S-Z', 'C-r')

-- Copilot
vim.keymap.set("n", "<leader>zc", ":CopilotChat<Return>", { desc = "Chat with Copilot" })
vim.keymap.set("v", "<leader>ze", ":CopilotChatExplain<Return>", { desc = "Expain code" })
vim.keymap.set("v", "<leader>zr", ":CopilotChatReview<Return>", { desc = "Review code" })
vim.keymap.set("v", "<leader>zf", ":CopilotChatFix<Return>", { desc = "Fix code issue" })
vim.keymap.set("v", "<leader>zo", ":CopilotChatOptimize<Return>", { desc = "Optimize code" })
vim.keymap.set("v", "<leader>zd", ":CopilotChatDocs<Return>", { desc = "Generate docs" })
vim.keymap.set("v", "<leader>zt", ":CopilotChatTests<Return>", { desc = "Optimize code" })
vim.keymap.set("v", "<leader>zm", ":CopilotChatCommit<Return>", { desc = "Generate commit for selection" })
vim.keymap.set("n", "<leader>zs", ":CopilotChatCommit<Return>", { desc = "Generate commit message" })

-- local builtin = require('telescope.builtin')
-- vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
-- vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
-- vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
-- vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

keymap.set("n", "<C-b>", function()
    vim.diagnostic.goto_next()
end, opts)
