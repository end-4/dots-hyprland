-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
vim.o.tabstop = 4 -- A TAB character looks like 4 spaces
vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 4 -- Number of spaces inserted when indenting

-- Disable persistent undo
vim.opt.undofile = false

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

return {
    "stevearc/conform.nvim",
    opts = {
        formatters = {
            prettier = {
                args = {
                    "--semi", -- true
                    "--single-quote", -- true
                    "--tab-width",
                    "4",
                    "--trailing-comma",
                    "es5",
                },
            },
        },
        s = {
            prettier = {
                prepend_args = {
                    "--semi",
                    "true",
                    "--single-quote",
                    "true",
                    "--tab-width",
                    "4",
                    "--trailing-comma",
                    "es5",
                },
            },
        },
        formatters_by_ft = {
            javascript = { "prettier" },
            typescript = { "prettier" },
            json = { "prettier" },
            html = { "prettier" },
            css = { "prettier" },
        },
    },
}
