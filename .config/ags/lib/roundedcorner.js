import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Gtk } = imports.gi;
const Lang = imports.lang;
import Cairo from 'gi://cairo?version=1.0';

export const dummyRegion = new Cairo.Region();
export const enableClickthrough = (self) => self.input_shape_combine_region(dummyRegion);

export const RoundedCorner = (place, props) => Widget.DrawingArea({
    ...props,
    hpack: place.includes('left') ? 'start' : 'end',
    vpack: place.includes('top') ? 'start' : 'end',
    setup: (widget) => Utils.timeout(1, () => {
        const c = widget.get_style_context().get_property('background-color', Gtk.StateFlags.NORMAL);
        const r = widget.get_style_context().get_property('border-radius', Gtk.StateFlags.NORMAL);
        widget.set_size_request(r, r);
        widget.connect('draw', Lang.bind(widget, (widget, cr) => {
            const c = widget.get_style_context().get_property('background-color', Gtk.StateFlags.NORMAL);
            const r = widget.get_style_context().get_property('border-radius', Gtk.StateFlags.NORMAL);
            // const borderColor = widget.get_style_context().get_property('color', Gtk.StateFlags.NORMAL);
            // const borderWidth = widget.get_style_context().get_border(Gtk.StateFlags.NORMAL).left; // ur going to write border-width: something anyway
            widget.set_size_request(r, r);

            switch (place) {
                case 'topleft':
                    cr.arc(r, r, r, Math.PI, 3 * Math.PI / 2);
                    cr.lineTo(0, 0);
                    break;

                case 'topright':
                    cr.arc(0, r, r, 3 * Math.PI / 2, 2 * Math.PI);
                    cr.lineTo(r, 0);
                    break;

                case 'bottomleft':
                    cr.arc(r, 0, r, Math.PI / 2, Math.PI);
                    cr.lineTo(0, r);
                    break;

                case 'bottomright':
                    cr.arc(0, 0, r, 0, Math.PI / 2);
                    cr.lineTo(r, r);
                    break;
            }

            cr.closePath();
            cr.setSourceRGBA(c.red, c.green, c.blue, c.alpha);
            cr.fill();
            // cr.setLineWidth(borderWidth);
            // cr.setSourceRGBA(borderColor.red, borderColor.green, borderColor.blue, borderColor.alpha);
            // cr.stroke();
        }));
    }),
});