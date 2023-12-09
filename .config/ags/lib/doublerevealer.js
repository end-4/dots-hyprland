const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Variable, Widget } from '../imports.js';

// TODO: Allow reveal update. Currently this just helps at declaration
export const DoubleRevealer = ({
    transition1 = 'slide_right',
    transition2 = 'slide_left',
    duration1 = 150,
    duration2 = 150,
    child,
    revealChild,
}) => {
    return Widget.Revealer({
        transition: transition1,
        transitionDuration: duration1,
        revealChild: revealChild,
        child: Widget.Revealer({
            transition: transition2,
            transitionDuration: duration2,
            revealChild: revealChild,
            child: child,
        })
    })
}