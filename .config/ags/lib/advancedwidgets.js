const { Gdk, Gtk } = imports.gi;
import { App, SCREEN_WIDTH, SCREEN_HEIGHT, Service, Utils, Variable, Widget } from '../imports.js';
const { Box, Button, EventBox, Label, Overlay, Revealer, Scrollable, Stack } = Widget;

export const MarginRevealer = ({
    transition = 'slide_down',
    child,
    revealChild,
    showClass = 'element-show', // These are for animation curve, they don't really hide
    hideClass = 'element-hide', // Don't put margins in these classes!
    extraProperties = [],
    ...rest
}) => {
    const widget = Scrollable({
        ...rest,
        properties: [
            ['revealChild', true], // It'll be set to false after init if it's supposed to hide
            ['transition', transition],
            ['show', () => {
                if (widget._revealChild) return;
                widget.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.NEVER);
                child.toggleClassName(hideClass, false);
                child.toggleClassName(showClass, true);
                widget._revealChild = true;
                child.css = 'margin: 0px;';
            }],
            ['hide', () => {
                if (!widget._revealChild) return;
                child.toggleClassName(hideClass, true);
                child.toggleClassName(showClass, false);
                widget._revealChild = false;
                if (widget._transition == 'slide_left')
                    child.css = `margin-right: -${child.get_allocated_width()}px;`;
                else if (widget._transition == 'slide_right')
                    child.css = `margin-left: -${child.get_allocated_width()}px;`;
                else if (widget._transition == 'slide_up')
                    child.css = `margin-bottom: -${child.get_allocated_height()}px;`;
                else if (widget._transition == 'slide_down')
                    child.css = `margin-top: -${child.get_allocated_height()}px;`;
            }],
            ['toggle', () => {
                console.log('toggle');
                if (widget._revealChild) widget._hide();
                else widget._show();
            }],
            ...extraProperties,
        ],
        child: child,
        hscroll: (revealChild ? 'never' : 'always'),
        vscroll: (revealChild ? 'never' : 'always'),
    });
    child.toggleClassName(`${revealChild ? showClass : hideClass}`, true);
    return widget;
}

// TODO: Allow reveal update. Currently this just helps at declaration
export const DoubleRevealer = ({
    transition1 = 'slide_right',
    transition2 = 'slide_left',
    duration1 = 150,
    duration2 = 150,
    child,
    revealChild,
}) => {
    return Revealer({
        transition: transition1,
        transitionDuration: duration1,
        revealChild: revealChild,
        child: Revealer({
            transition: transition2,
            transitionDuration: duration2,
            revealChild: revealChild,
            child: child,
        })
    })
}
