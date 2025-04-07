import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Gtk } = imports.gi;
const Lang = imports.lang;

export const AnimatedSlider = ({
    className,
    value,
    ...rest
}) => {
    return Widget.DrawingArea({
        className: `${className}`,
        setup: (self) => {
            self.connect('draw', Lang.bind(self, (self, cr) => {
                const styleContext = self.get_style_context();
                const allocatedWidth = self.get_allocated_width();
                const allocatedHeight = self.get_allocated_height();
                console.log(allocatedHeight, allocatedWidth)
                const minWidth = styleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
                const minHeight = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
                const radius = styleContext.get_property('border-radius', Gtk.StateFlags.NORMAL);
                const bg = styleContext.get_property('background-color', Gtk.StateFlags.NORMAL);
                const fg = styleContext.get_property('color', Gtk.StateFlags.NORMAL);
                const value = styleContext.get_property('font-size', Gtk.StateFlags.NORMAL) / 100;
                self.set_size_request(-1, minHeight);
                const width = allocatedHeight;
                const height = minHeight;

                cr.arc(radius, radius, radius, -1 * Math.PI, -0.5 * Math.PI); // Top-left
                cr.arc(width - radius, radius, radius, -0.5 * Math.PI, 0); // Top-right
                cr.arc(width - radius, height - radius, radius, 0, 0.5 * Math.PI); // Bottom-left
                cr.arc(radius, height - radius, radius, 0.5 * Math.PI, 1 * Math.PI); // Bottom-right
                cr.setSourceRGBA(bg.red, bg.green, bg.blue, bg.alpha);
                cr.closePath();
                cr.fill();

                // const valueWidth = width * value;
                // cr.arc(radius, radius, radius, -1 * Math.PI, -0.5 * Math.PI); // Top-left
                // cr.arc(valueWidth - radius, radius, radius, -0.5 * Math.PI, 0); // Top-right
                // cr.arc(valueWidth - radius, height - radius, radius, 0, 0.5 * Math.PI); // Bottom-left
                // cr.arc(radius, height - radius, radius, 0.5 * Math.PI, 1 * Math.PI); // Bottom-right
                // cr.setSourceRGBA(fg.red, fg.green, fg.blue, fg.alpha);
                // cr.closePath();
                // cr.fill();

            }));
        },
        ...rest,
    })
}
