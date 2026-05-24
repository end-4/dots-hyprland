-- nwg-displays bridge
local monitors_file = HOME .. "/.config/hypr/monitors.conf"
if is_file_exists(monitors_file) then
    local f = io.open(monitors_file, "r")
    if f then
        for line in f:lines() do
            local output, w, h, r, x, y, scale = line:match(
                "^monitor=([^,]+),(%d+)x(%d+)@([%d%.]+),(%d+)x(%d+),([%d%.]+)"
            )
            if output then
                hl.monitor({
                    output = output,
                    mode = w .. "x" .. h .. "@" .. r,
                    position = x .. "x" .. y,
                    scale = scale
                })
            end
        end
        f:close()
    end
end
