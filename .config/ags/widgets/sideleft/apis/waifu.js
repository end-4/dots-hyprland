const { Gdk, GLib, Gtk, Pango } = imports.gi;
import { App, Utils, Widget } from '../../../imports.js';
const { Box, Button, Entry, EventBox, Icon, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from "../../../lib/materialicon.js";
import { setupCursorHover, setupCursorHoverInfo } from "../../../lib/cursorhover.js";
import WaifuService from '../../../services/waifus.js';

const MESSAGE_SCROLL_DELAY = 13; // In milliseconds, the time before an updated message scrolls to bottom

// Create cache folder and clear pics from previous session
Utils.exec(`bash -c 'mkdir -p ${GLib.get_user_cache_dir()}/ags/media/waifus'`);
Utils.exec(`bash -c 'rm ${GLib.get_user_cache_dir()}/ags/media/waifus/*'`);

const CommandButton = (command) => Button({
    className: 'sidebar-chat-chip sidebar-chat-chip-action txt txt-small',
    onClicked: () => sendMessage(command),
    setup: setupCursorHover,
    label: command,
});

export const waifuTabIcon = Box({
    hpack: 'center',
    className: 'sidebar-chat-apiswitcher-icon',
    homogeneous: true,
    children: [
        MaterialIcon('photo_library', 'norm'),
    ]
});

const WaifuImage = (taglist) => {
    const colorIndicator = Box({
        className: `sidebar-chat-indicator`,
    });
    const downloadIndicator = Label({
        className: 'sidebar-waifu-txt txt-smallie txt',
        xalign: 0,
        label: 'Downloading image...',
    });
    const blockHeading = Box({
        className: 'sidebar-waifu-content',
        vertical: true,
        children: [
            Box({
                children: taglist.map((tag) => CommandButton(tag))
            }),
            downloadIndicator,
        ]
    });
    const blockImage = Box({
        hpack: 'start',
        className: 'sidebar-waifu-image',
    })
    const thisBlock = Box({
        className: 'sidebar-chat-message',
        properties: [
            ['update', (imageData) => {
                const { signature, url, source, dominant_color, is_nsfw, width, height, tags } = imageData;
                const imagePath = `${GLib.get_user_cache_dir()}/ags/media/waifus/${signature}`;
                // Start download
                Utils.execAsync(['bash', '-c', `wget -O '${imagePath}' '${url}'`])
                    .then(() => {
                        blockImage.css = `background-image:url('${imagePath}');`;
                        downloadIndicator.destroy();
                    })
                    .catch(print);
                colorIndicator.css = `background-color: ${dominant_color};`;
                // Width allocation
                const widgetWidth = Math.floor(waifuContent.get_allocated_width() * 0.75); // idk tbh
                blockImage.set_size_request(widgetWidth, Math.ceil(widgetWidth * height / width));
            }],
        ],
        children: [
            colorIndicator,
            Box({
                vertical: true,
                className: 'spacing-v-10',
                children: [
                    blockHeading,
                    blockImage,
                ]
            })
        ],
        setup: (self) => Utils.timeout(MESSAGE_SCROLL_DELAY, () => {
            var adjustment = waifuView.get_vadjustment();
            adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size());
        })
    });
    return thisBlock;
}

const waifuContent = Box({
    className: 'spacing-v-15',
    vertical: true,
    vexpand: true,
    properties: [
        ['map', new Map()],
    ],
    connections: [
        [WaifuService, (box, id) => {
            if (id === undefined) return;
            console.log('new', WaifuService.queries[id]);
            const newImageBlock = WaifuImage(WaifuService.queries[id]);
            box.add(newImageBlock);
            box.show_all();
            box._map.set(id, newImageBlock);
        }, 'newResponse'],
        [WaifuService, (box, id) => {
            if (id === undefined) return;
            const data = WaifuService.responses[id];
            if (!data) return;
            const imageBlock = box._map.get(id);
            imageBlock._update(data);
        }, 'updateResponse'],
    ]
});

export const waifuView = Scrollable({
    className: 'sidebar-chat-viewport',
    vexpand: true,
    child: Box({
        vertical: true,
        children: [
            waifuContent,
        ]
    }),
    setup: (scrolledWindow) => {
        // Show scrollbar
        scrolledWindow.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        const vScrollbar = scrolledWindow.get_vscrollbar();
        vScrollbar.get_style_context().add_class('sidebar-scrollbar');
        // Avoid click-to-scroll-widget-to-view behavior
        Utils.timeout(1, () => {
            const viewport = scrolledWindow.child;
            viewport.set_focus_vadjustment(new Gtk.Adjustment(undefined));
        })
    }
});

export const waifuCommands = Box({
    className: 'spacing-h-5',
    children: [
        Box({ hexpand: true }),
        CommandButton('/clear'),
    ]
});

export const sendMessage = (text) => {
    // Do something on send
    // Commands
    if (text.startsWith('/')) {
        if (text.startsWith('/clear')) {
            const kids = waifuContent.get_children();
            for (let i = 0; i < kids.length; i++) {
                const child = kids[i];
                child.destroy();
            }
        }
    }
    else WaifuService.fetch(text);
}