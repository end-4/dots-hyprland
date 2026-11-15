-- Custom window rules

-- Windows-style Display Switcher GUI (Super + P)
hl.window_rule({ match = { class = "^(hypr-monitors-gui)$" }, float = true })
hl.window_rule({ match = { class = "^(hypr-monitors-gui)$" }, center = true })
hl.window_rule({ match = { class = "^(hypr-monitors-gui)$" }, pin = true })
