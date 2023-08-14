const { Gdk, Gtk } = imports.gi;
const { App, Widget } = ags;
const { Hyprland } = ags.Service;
const { execAsync } = ags.Utils;

const SCALE = 0.08;
const TARGET = [Gtk.TargetEntry.new('text/plain', Gtk.TargetFlags.SAME_APP, 0)];

function substitute(str) {
    const subs = [
        { from: 'Caprine', to: 'facebook-messenger' },
    ];

    for (const { from, to } of subs) {
        if (from === str)
            return to;
    }

    return str;
}

const client = ({ address, size: [w, h], class: c, title }) => Widget({
    type: 'button',
    className: 'client',
    child: {
        type: 'icon',
        style: `
            min-width: ${w * SCALE}px;
            min-height: ${h * SCALE}px;
        `,
        icon: substitute(c),
    },
    tooltip: title,
    onMiddleClick: () => execAsync('hyprctl dispatch closewindow address:' + address).catch(print),
    setup: button => {
        button.drag_source_set(Gdk.ModifierType.BUTTON1_MASK, TARGET, Gdk.DragAction.COPY);
        button.drag_source_set_icon_name(substitute(c));
        button.connect('drag-data-get', (_w, _c, data) => data.set_text(address, address.length));
    },
});

const workspace = index => {
    const fixed = Gtk.Fixed.new();
    const widget = Widget({
        type: 'box',
        className: 'workspace',
        valign: 'center',
        style: `
        min-width: ${1920 * SCALE}px;
        min-height: ${1080 * SCALE}px;
        `,
        connections: [[Hyprland, box => {
            box.toggleClassName('active', Hyprland.active.workspace.id === index);
        }]],
        children: [{
            type: 'eventbox',
            hexpand: true,
            vexpand: true,
            onClick: () => execAsync(`hyprctl dispatch workspace ${index}`).catch(print),
            setup: eventbox => {
                eventbox.drag_dest_set(Gtk.DestDefaults.ALL, TARGET, Gdk.DragAction.COPY);
                eventbox.connect('drag-data-received', (_w, _c, _x, _y, data) => {
                    execAsync(`hyprctl dispatch movetoworkspacesilent ${index},address:${data.get_text()}`).catch(print);
                });
            },
            child: fixed,
        }],
    });
    widget.update = clients => {
        clients = clients.filter(({ workspace: { id } }) => id === index);

        // this is for my monitor layout
        // shifts clients back by 1920px if necessary
        clients = clients.map(client => {
            const [x, y] = client.at;
            if (x > 1920)
                client.at = [x - 1920, y];
            return client;
        });

        fixed.get_children().forEach(ch => ch.destroy());
        clients.forEach(c => c.mapped && fixed.put(client(c), c.at[0] * SCALE, c.at[1] * SCALE));
        fixed.show_all();
    };
    return widget;
};

const arr = n => {
    const array = [];
    for (let i = 1; i <= n; ++i)
        array.push(i);

    return array;
};

Widget.widgets['overview'] = ({ workspaces = 10, windowName = 'overview' }) => Widget({
    type: 'box',
    className: 'overview',
    children: arr(workspaces).map(workspace),
    properties: [['update', box => {
        execAsync('hyprctl -j clients').then(clients => {
            const json = JSON.parse(clients);
            box.get_children().forEach(ch => ch.update(json));
        }).catch(print);
    }]],
    setup: box => box._update(box),
    connections: [[Hyprland, box => {
        if (!App.getWindow(windowName).visible)
            return;

        box._update(box);
    }]],
});

const popup = (name, child) => ({
    name,
    popup: true,
    focusable: true,
    child: {
        type: 'layout',
        layout: 'center',
        window: name,
        child,
    },
});

var overview = popup('overview', {
    type: 'overview',
});



