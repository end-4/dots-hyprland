import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { setupCursorHover } from '../../lib/cursorhover.js';
import { MaterialIcon } from '../../lib/materialicon.js';
const { Box, Button, Icon, Label, Revealer } = Widget;

export const SidebarModule = ({
    icon,
    name,
    child
}) => {
    const headerButtonIcon = MaterialIcon('expand_more', 'norm');
    const header = Box({
        className: 'spacing-h-10',
        children: [
            icon,
            Label({
                className: 'txt-norm txt',
                label: `${name}`,
            }),
            Box({
                hexpand: true,
            }),
            Button({
                className: 'sidebar-module-btn-arrow txt',
                child: headerButtonIcon,
                onClicked: () => {
                    console.log('clicked');
                    content.revealChild = !content.revealChild;
                    headerButtonIcon.label = content.revealChild ? 'expand_less' : 'expand_more';
                },
                setup: setupCursorHover,
            })
        ]
    });
    const content = Revealer({
        revealChild: true,
        transition: 'slide_down',
        transitionDuration: 200,
        child: Box({
            className: 'margin-top-5',
            homogeneous: true,
            children: [child],
        }),
    });
    return Box({
        className: 'sidebar-module',
        vertical: true,
        children: [
            header,
            content,
        ]
    });
}