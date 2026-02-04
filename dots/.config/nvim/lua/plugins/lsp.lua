return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                clangd = {
                    -- Thêm tham số command line vào đây
                    cmd = {
                        "clangd",
                        "--background-index",
                        "--clang-tidy",
                        "--header-insertion=iwyu",
                        "--completion-style=detailed",
                        "--function-arg-placeholders",
                        "--fallback-style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never}",
                    },
                },
                pylsp = {
                    settings = {
                        pylsp = {
                            plugins = {
                                rope_autoimport = {
                                    enabled = true,
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}
