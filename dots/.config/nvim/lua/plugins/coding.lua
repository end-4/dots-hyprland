-- Copilot
return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        build = ":Copilot auth",
        event = "InsertEnter",
        opts = {
            suggestion = {
                enabled = not vim.g.ai_cmp,
                auto_trigger = true,
                keymap = {
                    accept = "<Tab>", -- handled by nvim-cmp / blink.cmp
                    next = "<M-]>",
                    prev = "<M-[>",
                },
            },
            panel = { enabled = false },
            filetypes = {
                markdown = true,
                help = true,
            },
        },
    },

    {
        "numToStr/Comment.nvim",
        opts = {
            opleader = {
                ---Line-comment keymap
                line = "gc",
                ---Block-comment keymap
                block = "gb",
            },
        },
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        opts = {
            mappings = {
                complete = {
                    insert = "<Tab>",
                },
                close = {
                    normal = "q",
                    insert = "<C-q>",
                },
                reset = {
                    normal = "<C-l>",
                    insert = "<C-l>",
                },
                submit_prompt = {
                    normal = "<CR>",
                    insert = "<C-s>",
                },
                toggle_sticky = {
                    detail = "Makes line under cursor sticky or deletes sticky line.",
                    normal = "gr",
                },
                accept_diff = {
                    normal = "<C-y>",
                    insert = "<C-y>",
                },
                jump_to_diff = {
                    normal = "gj",
                },
                quickfix_answers = {
                    normal = "gqa",
                },
                quickfix_diffs = {
                    normal = "gqd",
                },
                yank_diff = {
                    normal = "gy",
                    register = '"', -- Default register to use for yanking
                },
                show_diff = {
                    normal = "gd",
                    full_diff = false, -- Show full diff instead of unified diff when showing diff window
                },
                show_info = {
                    normal = "gi",
                },
                show_context = {
                    normal = "gc",
                },
                show_help = {
                    normal = "gh",
                },
            },
        },
    },

    { "mg979/vim-visual-multi" },
    {
        "CRAG666/code_runner.nvim",
        config = function()
            require("code_runner").setup({
                -- mode = "tab",
                filetype = {
                    cpp = "cd $dir && g++ $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt && rm $fileNameWithoutExt",
                },
                term = {
                    position = "vsplit",
                    size = 0.1,
                },
            })
        end,
    },
}
