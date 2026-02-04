return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
        "nvim-neotest/neotest-jest",
    },
    opts = function(_, opts)
        table.insert(
            opts.adapters,
            require("neotest-jest")({
                jestConfigFile = function(file)
                    if file:find("package.json") then
                        return vim.fn.getcwd() .. "/jest.config.ts"
                    end
                    return vim.fn.getcwd() .. "/jest.config.js"
                end,
                env = { CI = true },
                cwd = function(path)
                    return vim.fn.getcwd()
                end,
            })
        )
    end,
}
