import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box, Button, Label } = Widget;

export const SidebarModule = ({
    name,
    child
}) => {
    return Box({
        className: 'sidebar-module',
        vertical: true,
        children: [
            Button({
                child: Box({
                    children: [
                        Label({
                            className: 'txt-small txt',
                            label: `${name}`,
                        }),
                        Box({
                            hexpand: true,
                        }),
                        Label({
                            className: 'sidebar-module-btn-arrow',
                        })
                    ]
                })
            })
        ]
    });
}