const { Gdk, Gtk } = imports.gi;
const { App, Widget } = ags;
const { Applications, Hyprland } = ags.Service;
const { execAsync, exec } = ags.Utils;

export const SidebarRight = () => Widget.Box({
    vexpand: true,
    className: 'sidebar-right',
})