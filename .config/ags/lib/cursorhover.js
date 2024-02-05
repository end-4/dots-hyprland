const { Gdk } = imports.gi;

export function setupCursorHover(button) { // Hand pointing cursor on hover
    const display = Gdk.Display.get_default();
    button.connect('enter-notify-event', () => {
        const cursor = Gdk.Cursor.new_from_name(display, 'pointer');
        button.get_window().set_cursor(cursor);
    });

    button.connect('leave-notify-event', () => {
        const cursor = Gdk.Cursor.new_from_name(display, 'default');
        button.get_window().set_cursor(cursor);
    });

}

export function setupCursorHoverAim(button) { // Crosshair cursor on hover
    button.connect('enter-notify-event', () => {
        const display = Gdk.Display.get_default();
        const cursor = Gdk.Cursor.new_from_name(display, 'crosshair');
        button.get_window().set_cursor(cursor);
    });

    button.connect('leave-notify-event', () => {
        const display = Gdk.Display.get_default();
        const cursor = Gdk.Cursor.new_from_name(display, 'default');
        button.get_window().set_cursor(cursor);
    });
}

export function setupCursorHoverGrab(button) { // Hand ready to grab on hover
    button.connect('enter-notify-event', () => {
        const display = Gdk.Display.get_default();
        const cursor = Gdk.Cursor.new_from_name(display, 'grab');
        button.get_window().set_cursor(cursor);
    });

    button.connect('leave-notify-event', () => {
        const display = Gdk.Display.get_default();
        const cursor = Gdk.Cursor.new_from_name(display, 'default');
        button.get_window().set_cursor(cursor);
    });
}

export function setupCursorHoverInfo(button) { // "?" mark cursor on hover
    const display = Gdk.Display.get_default();
    button.connect('enter-notify-event', () => {
        const cursor = Gdk.Cursor.new_from_name(display, 'help');
        button.get_window().set_cursor(cursor);
    });

    button.connect('leave-notify-event', () => {
        const cursor = Gdk.Cursor.new_from_name(display, 'default');
        button.get_window().set_cursor(cursor);
    });
}

