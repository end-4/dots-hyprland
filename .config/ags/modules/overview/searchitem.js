import Widget from 'resource:///com/github/Aylur/ags/widget.js';

export const searchItem = ({ materialIconName, name, actionName, content, onActivate, extraClassName = '', ...rest }) => {
    const actionText = Widget.Revealer({
        revealChild: false,
        transition: "crossfade",
        transitionDuration: 200,
        child: Widget.Label({
            className: 'overview-search-results-txt txt txt-small txt-action',
            label: `${actionName}`,
        })
    });
    const actionTextRevealer = Widget.Revealer({
        revealChild: false,
        transition: "slide_left",
        transitionDuration: 300,
        child: actionText,
    })
    return Widget.Button({
        className: `overview-search-result-btn txt ${extraClassName}`,
        onClicked: onActivate,
        child: Widget.Box({
            children: [
                Widget.Box({
                    vertical: false,
                    children: [
                        Widget.Label({
                            className: `icon-material overview-search-results-icon`,
                            label: `${materialIconName}`,
                        }),
                        Widget.Box({
                            vertical: true,
                            children: [
                                Widget.Label({
                                    hpack: 'start',
                                    className: 'overview-search-results-txt txt-smallie txt-subtext',
                                    label: `${name}`,
                                    truncate: "end",
                                }),
                                Widget.Label({
                                    hpack: 'start',
                                    className: 'overview-search-results-txt txt-norm',
                                    label: `${content}`,
                                    truncate: "end",
                                }),
                            ]
                        }),
                        Widget.Box({ hexpand: true }),
                        actionTextRevealer,
                    ],
                })
            ]
        }),
        setup: (self) => self
            .on('focus-in-event', (button) => {
                actionText.revealChild = true;
                actionTextRevealer.revealChild = true;
            })
            .on('focus-out-event', (button) => {
                actionText.revealChild = false;
                actionTextRevealer.revealChild = false;
            })
        ,
    });
}
