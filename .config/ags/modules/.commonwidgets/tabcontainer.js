import Variable from 'resource:///com/github/Aylur/ags/variable.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box, Button, Label, Overlay, Stack } = Widget;
import { MaterialIcon } from './materialicon.js';
import { NavigationIndicator } from './cairo_navigationindicator.js';
import { setupCursorHover } from '../.widgetutils/cursorhover.js';

export const TabContainer = ({ icons, names, children, className = '', setup = () => {}, ...rest }) => {
    const shownIndex = Variable(0);
    let previousShownIndex = 0;
    const count = Math.min(icons.length, names.length, children.length);
    const tabs = Box({
        homogeneous: true,
        children: Array.from({ length: count }, (_, i) => Button({ // Tab button
            className: 'tab-btn',
            onClicked: () => shownIndex.value = i,
            setup: setupCursorHover,
            child: Box({
                hpack: 'center',
                vpack: 'center',
                className: 'spacing-h-5 txt-small',
                children: [
                    MaterialIcon(icons[i], 'norm'),
                    Label({
                        label: names[i],
                    })
                ]
            })
        })),
        setup: (self) => self.hook(shownIndex, (self) => {
            self.children[previousShownIndex].toggleClassName('tab-btn-active', false);
            self.children[shownIndex.value].toggleClassName('tab-btn-active', true);
            previousShownIndex = shownIndex.value;
        }),
    });
    const tabIndicatorLine = Box({
        hexpand: true,
        vertical: true,
        homogeneous: true,
        setup: (self) => self.hook(shownIndex, (self) => {
            self.children[0].css = `font-size: ${shownIndex.value}px;`;
        }),
        children: [NavigationIndicator({
            className: 'tab-indicator',
            count: count,
            css: `font-size: ${shownIndex.value}px;`,
        })],
    });
    const tabSection = Box({
        vertical: true,
        hexpand: true,
        children: [
            tabs,
            tabIndicatorLine
        ]
    });
    const contentStack = Stack({
        transition: 'slide_left_right',
        children: children.reduce((acc, currentValue, index) => {
            acc[index] = currentValue;
            return acc;
        }, {}),
        setup: (self) => self.hook(shownIndex, (self) => {
            self.shown = `${shownIndex.value}`;
        }),
    });
    const mainBox = Box({
        attribute: {
            children: children,
            shown: shownIndex,
            names: names,
        },
        vertical: true,
        className: `spacing-v-5 ${className}`,
        setup: (self) => {
            self.pack_start(tabSection, false, false, 0);
            self.pack_end(contentStack, true, true, 0);
            setup(self);
        },
        ...rest,
    });
    mainBox.nextTab = () => shownIndex.value = Math.min(shownIndex.value + 1, count - 1);
    mainBox.prevTab = () => shownIndex.value = Math.max(shownIndex.value - 1, 0);
    mainBox.cycleTab = () => shownIndex.value = (shownIndex.value + 1) % count;

    return mainBox;
}
