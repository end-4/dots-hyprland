const { Widget } = ags;
const { Gtk } = imports.gi;

Widget.widgets['modules/corners'] = ({ place }) => Widget({
    type: Gtk.DrawingArea.new,
    className: 'corner',
    hexpand: true,
    vexpand: true,
    halign: place.includes('left') ? 'start' : 'end',
    valign: place.includes('top') ? 'start' : 'end',
    setup: widget => { widget.set_size_request(0, 0); },
    connections: [['draw', (widget, cr) => {
        const c = widget.get_style_context().get_property('background-color', Gtk.StateFlags.NORMAL);
        const r = widget.get_style_context().get_property('border-radius', Gtk.StateFlags.NORMAL);
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
    }]],
});

var corner_topleft = {
    name: 'cornertl',
    anchor: ['top', 'left'],
    exclusive: false,
    child: {
        type: 'modules/corners',
        place: 'topleft',
    },
}
var corner_topright = {
    name: 'cornertr',
    anchor: ['top', 'right'],
    exclusive: false,
    child: {
        type: 'modules/corners',
        place: 'topright',
    },
}
var corner_bottomleft = {
    name: 'cornerbl',
    anchor: ['bottom', 'left'],
    exclusive: false,
    child: {
        type: 'modules/corners',
        place: 'bottomleft',
    },
}
var corner_bottomright = {
    name: 'cornerbr',
    anchor: ['bottom', 'right'],
    exclusive: false,
    child: {
        type: 'modules/corners',
        place: 'bottomright',
    },
}

