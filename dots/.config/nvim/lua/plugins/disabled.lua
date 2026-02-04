return {
    { "akinsho/bufferline.nvim", enabled = false },
    {
        "ibhagwan/fzf-lua",
        -- optional for icon support
        keys = {
            { "<leader>fg", false },
        },
    },

    {
        "folke/flash.nvim",
        opts = {
            modes = {
                treesitter = {
                    -- tắt hint label a,b,c...
                    labels = "",
                    label = {
                        before = false,
                        after = false,
                        style = "overlay",
                        min_pattern_length = 9999,
                    },
                    highlight = {
                        backdrop = false,
                        matches = false,
                    },
                },
            },
        },
    },
}
