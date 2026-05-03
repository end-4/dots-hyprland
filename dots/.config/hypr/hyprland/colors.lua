hl.config({
    general = {
        col = {
            active_border   = "rgba(44464f77)",
            inactive_border = "rgba(1a1b2033)",
        },
    },
    misc = {
        background_color = "rgba(121318FF)",
    },
})

-- Don't know if plugins changed syntax too.
-- plugin {
--     hyprbars {
--         -- Honestly idk if it works like css, but well, why not
--         bar_text_font = Google Sans Flex Medium, Rubik, Geist, AR One Sans, Reddit Sans, Inter, Roboto, Ubuntu, Noto Sans, sans-serif
--         bar_height = 30
--         bar_padding = 10
--         bar_button_padding = 5
--         bar_precedence_over_border = true
--         bar_part_of_window = true
--
--         bar_color = rgba(121318FF)
--         col.text = rgba(e2e2e9FF)
--
--
--         -- example buttons (R -> L)
--         -- hyprbars-button = color, size, on-click
--         hyprbars-button = rgb(e2e2e9), 13, 󰖭, hyprctl dispatch killactive
--         hyprbars-button = rgb(e2e2e9), 13, 󰖯, hyprctl dispatch fullscreen 1
--         hyprbars-button = rgb(e2e2e9), 13, 󰖰, hyprctl dispatch movetoworkspacesilent special
--     }
-- }

hl.window_rule({ -- not sure how to syntax "pin 1"
    match        = { pin = 1 },
    border_color = "rgba(afc6ffAA) rgba(afc6ff77)",
})
