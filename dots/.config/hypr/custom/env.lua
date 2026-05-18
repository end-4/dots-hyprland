local function parse_envs(str)
    local envs = ""
    local rstr = str
    for w in str:gmatch("$[%w_]+") do
        if not string.match(envs, w) then
            envs = w .. " " .. envs
        end
    end
    for w in envs:gmatch("[%w_]+") do
        local env = os.getenv(w)
        if env then
            rstr = string.gsub(rstr, "$"..w, env)
        else
            rstr = string.gsub(rstr,"$".. w, "")
        end
    end
    return rstr
end


-- Example
-- hl.env("ANDROID_HOME", parse_envs("$HOME/Android/Sdk"))