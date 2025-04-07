// Cursor names reference: https://docs.gtk.org/gdk4/ctor.Cursor.new_from_name.html
const { Gdk } = imports.gi;

export function setupCursorHover(button, cursorName = 'pointer') { // Hand pointing cursor on hover
    const display = Gdk.Display.get_default();
    button.connect('enter-notify-event', () => {
        const cursor = Gdk.Cursor.new_from_name(display, cursorName);
        button.get_window().set_cursor(cursor);
    });

    button.connect('leave-notify-event', () => {
        const cursor = Gdk.Cursor.new_from_name(display, 'default');
        button.get_window().set_cursor(cursor);
    });

}

export function setupCursorHoverAim(button) { // Crosshair cursor on hover
    setupCursorHover(button, 'crosshair');
}

export function setupCursorHoverGrab(button) { // Hand ready to grab on hover
    setupCursorHover(button, 'grab');
}

export function setupCursorHoverInfo(button) { // "?" mark cursor on hover
    setupCursorHover(button, 'help');
}

export function setupCursorHoverHResize(button) { // Resize left right
    setupCursorHover(button, 'ew-resize');
}

export function setupCursorHoverVResize(button) { // Resize up down
    setupCursorHover(button, 'ns-resize');
}
