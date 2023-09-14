const { Gdk, Gtk } = imports.gi;
const { App, Service, Widget } = ags;
const { Applications, Hyprland } = ags.Service;
const { execAsync, exec } = ags.Utils;
const { Box, EventBox } = ags.Widget;
const { MenuService } = ags.Service;

export const SidebarLeft = () => Box({
    className: 'test',
    vertical: true,
    children: [
        EventBox({
            onPrimaryClick: () => MenuService.close('sideleft'),
            onSecondaryClick: () => MenuService.close('sideleft'),
            onMiddleClick: () => MenuService.close('sideleft'),
        }),
        Box({
            vertical: true,
            vexpand: true,
            className: 'sidebar-left sideleft-hide',
            children: [
                Widget.Button({
                    onHoverLost: () => {
                        console.log('lost!');
                        MenuService.close('sideleft');
                    },
                    style: 'min-width: 40px; min-height: 40px;',
                })
            ],
            connections: [[MenuService, box => {
                box.toggleClassName('sideleft-hide', !('sideleft' === MenuService.opened));
            }]],
        }),
    ]
});