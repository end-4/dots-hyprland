const { Gdk, Gtk } = imports.gi;

const CLICK_BRIGHTEN_AMOUNT = 0.13;

export function setupCursorHover(button) {
    var clicked = false;
    var dummy = false;
    var cursorX = 0;
    var cursorY = 0;
    const styleContext = button.get_style_context();
    var clickColor = styleContext.get_property('background-color', Gtk.StateFlags.HOVER);
    clickColor.green += CLICK_BRIGHTEN_AMOUNT;
    clickColor.blue += CLICK_BRIGHTEN_AMOUNT;
    clickColor.red += CLICK_BRIGHTEN_AMOUNT;
    clickColor = clickColor.to_string();
    
    const display = Gdk.Display.get_default();
    button.connect('enter-notify-event', () => {
        const cursor = Gdk.Cursor.new_from_name(display, 'pointer');
        button.get_window().set_cursor(cursor);
    });

    button.connect('leave-notify-event', () => {
        const cursor = Gdk.Cursor.new_from_name(display, 'default');
        button.get_window().set_cursor(cursor);
    });

    // button.add_events(Gdk.EventMask.POINTER_MOTION_MASK);
    // button.connect('motion-notify-event', (widget, event) => {
    //     [dummy, cursorX, cursorY] = event.get_coords(); // Get the mouse coordinates relative to the widget
    //     if(!clicked) widget.style = `
    //         background-image: radial-gradient(circle at ${cursorX}px ${cursorY}px, rgba(0,0,0,0), rgba(0,0,0,0) 0%, rgba(0,0,0,0) 0%, ${clickColor} 0%, ${clickColor} 0%, ${clickColor} 0%, ${clickColor} 0%, rgba(0,0,0,0) 0%, rgba(0,0,0,0) 0%);
    //     `;
    // });

    // button.connect('button-press-event', (widget, event) => {
    //     clicked = true;
    //     [dummy, cursorX, cursorY] = event.get_coords(); // Get the mouse coordinates relative to the widget
    //     cursorX = Math.round(cursorX); cursorY = Math.round(cursorY);
    //     widget.style = `
    //         background-image: radial-gradient(circle at ${cursorX}px ${cursorY}px, rgba(0,0,0,0), rgba(0,0,0,0) 0%, rgba(0,0,0,0) 0%, ${clickColor} 0%, ${clickColor} 0%, ${clickColor} 0%, ${clickColor} 0%, rgba(0,0,0,0) 0%, rgba(0,0,0,0) 0%);
    //     `;
    //     widget.toggleClassName('growingRadial', true);
    //     widget.style = `
    //         background-image: radial-gradient(circle at ${cursorX}px ${cursorY}px, rgba(0,0,0,0), rgba(0,0,0,0) 0%, rgba(0,0,0,0) 0%, ${clickColor} 0%, ${clickColor} 0%, ${clickColor} 70%, ${clickColor} 70%, rgba(0,0,0,0) 70%, rgba(0,0,0,0) 70%);
    //     `
    // });
    // button.connect('button-release-event', (widget, event) => {
    //     widget.toggleClassName('growingRadial', false);
    //     widget.toggleClassName('fadingRadial', false);
    //     widget.style = `
    //     background-image: radial-gradient(circle at ${cursorX}px ${cursorY}px, rgba(0,0,0,0), rgba(0,0,0,0) 0%, rgba(0,0,0,0) 0%, rgba(0,0,0,0) 0%, rgba(0,0,0,0) 0%, rgba(0,0,0,0) 70%, rgba(0,0,0,0) 70%, rgba(0,0,0,0) 70%, rgba(0,0,0,0) 70%);
    //     `
    //     clicked = false;
    // });
}

export function setupCursorHoverAim(button) {
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