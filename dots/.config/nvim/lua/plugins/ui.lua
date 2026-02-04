return {
    -- {
    --     "folke/drop.nvim",
    --     event = "VeryLazy",
    --     config = function()
    --         require("drop").setup({
    --             -- Chọn theme: "matrix", "stars", "snow", "leaves", "spring", "summer"
    --             theme = "auto",
    --
    --             -- Tự động bật screensaver sau bao lâu (tính bằng ms, 1000 = 1 giây)
    --             screensaver = 1000 * 60 * 5, -- 5 phút
    --
    --             -- Các loại file không hiện screensaver (ví dụ đang gõ dashboard)
    --             filetypes = { "dashboard", "alpha", "starter" },
    --             transparent = true,
    --
    --             winblend = 100, -- winblend for the drop window
    --         })
    --     end,
    -- },
    {
        "tamton-aquib/duck.nvim",
        config = function()
            vim.keymap.set("n", "<leader>dd", function()
                require("duck").hatch()
            end, {})
            vim.keymap.set("n", "<leader>dk", function()
                require("duck").cook()
            end, {})
            vim.keymap.set("n", "<leader>da", function()
                require("duck").cook_all()
            end, {})
        end,
    },
}
