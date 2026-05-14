require("hyprland/lib")

hl.on("hyprland.start", function()
   local homeDir = os.getenv("HOME")
   if string.len(homeDir) == 0 then
      return
   end
   local baseCustomDir = homeDir .. "/.config/hypr/custom"
   local files = {
      baseCustomDir .. "/env.lua",
      baseCustomDir .. "/execs.lua",
      baseCustomDir .. "/general.lua",
      baseCustomDir .. "/keybinds.lua",
      baseCustomDir .. "/rules.lua",
      baseCustomDir .. "/variables.lua"
   }
   local createdFiles = 0
   for _, file in ipairs(files) do
      if not is_file_exists(file) then
         create_if_not_exists(file)
         createdFiles = createdFiles + 1
      end
   end

   if createdFiles > 0 then
      hl.exec_cmd("notify-send 'Hyprland config' 'Created " .. createdFiles .. " custom Hyprland config files in " .. baseCustomDir .. "' -a 'Hyprland'")
      hl.exec_cmd("hyprctl reload")
   end
end)
