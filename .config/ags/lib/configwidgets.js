const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Variable, Widget } from '../imports.js';
import { MaterialIcon } from './materialicon.js';
import { setupCursorHover } from './cursorhover.js';
const { Box, Button, Entry, EventBox, Icon, Label, Revealer, Scrollable, Stack } = Widget;

export const ConfigToggle = ({ icon, name, desc = '', initValue, onChange, ...props }) => {
    let value = initValue;
    const toggleIcon = Label({
        className: `icon-material txt-bold`,
        label: `${value ? 'check' : ''}`,
    })
    const toggleButtonIndicator = Box({
        className: `switch-fg ${value ? 'switch-fg-true' : ''}`,
        vpack: 'center',
        hpack: 'start',
        homogeneous: true,
        children: [toggleIcon,],
    });
    const toggleButton = Box({
        hpack: 'end',
        className: `switch-bg ${value ? 'switch-bg-true' : ''}`,
        homogeneous: true,
        children: [toggleButtonIndicator,],
    });
    const widgetContent = Box({
        tooltipText: desc,
        className: 'txt spacing-h-5 configtoggle-box',
        children: [
            MaterialIcon(icon, 'norm'),
            Label({
                className: 'txt txt-small',
                label: name,
            }),
            Box({ hexpand: true }),
            toggleButton,
        ]
    });
    const interactionWrapper = Button({
        ...props,
        child: widgetContent,
        setup: setupCursorHover,
        onClicked: () => { // mouse up/kb press
            value = !value;
            toggleIcon.toggleClassName('switch-fg-toggling-false', false);
            toggleIcon.label = `${value ? 'check' : ''}`;
            toggleIcon.toggleClassName('txt-poof', !value);
            toggleButtonIndicator.toggleClassName('switch-fg-true', value);
            toggleButton.toggleClassName('switch-bg-true', value);
            onChange(interactionWrapper, value);
        },
        setup: (button) => {
            button.connect('pressed', () => { // mouse down
                toggleIcon.toggleClassName('txt-poof', true);
                toggleIcon.toggleClassName('switch-fg-true', false);
                if(!value) toggleIcon.toggleClassName('switch-fg-toggling-false', true);
            });
        }
    });
    return interactionWrapper;
}