import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { setupCursorHover } from '../../.widgetutils/cursorhover.js';
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
const { Box, Button, Icon, Label, Revealer } = Widget;

export default ({
    icon,
    name,
    child,
    revealChild = true,
}) => {
    const headerButtonIcon = MaterialIcon(revealChild ? 'expand_less' : 'expand_more', 'norm');
    const header = Button({
        onClicked: () => {
            content.revealChild = !content.revealChild;
            headerButtonIcon.label = content.revealChild ? 'expand_less' : 'expand_more';
        },
        setup: setupCursorHover,
        child: Box({
            className: 'txt spacing-h-10',
            children: [
                icon,
                Label({
                    className: 'txt-norm',
                    label: `${name}`,
                }),
                Box({
                    hexpand: true,
                }),
                Box({
                    className: 'sidebar-module-btn-arrow',
                    homogeneous: true,
                    children: [headerButtonIcon],
                })
            ]
        })
    });
    const content = Revealer({
        revealChild: revealChild,
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