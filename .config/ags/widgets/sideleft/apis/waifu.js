const { Gdk, Gio, GLib, Gtk, Pango } = imports.gi;
import { App, Utils, Widget } from '../../../imports.js';
const { Box, Button, Entry, EventBox, Icon, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from "../../../lib/materialicon.js";
import { MarginRevealer } from '../../../lib/advancedrevealers.js';
import { setupCursorHover, setupCursorHoverInfo } from "../../../lib/cursorhover.js";
import WaifuService from '../../../services/waifus.js';

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
    var imagePath = '';
    var blockImageData = {};
    const ImageState = (icon, name) => Box({
        className: 'spacing-h-5',
        children: [
            Box({ hexpand: true }),
            Label({
                className: 'sidebar-waifu-txt txt-smallie txt',
                xalign: 0,
                label: name,
            }),
            MaterialIcon(icon, 'norm'),
        ]
    })
    const ImageAction = ({ name, icon, action }) => Button({
        className: 'sidebar-waifu-image-action txt-norm icon-material',
        tooltipText: name,
        label: icon,
        onClicked: action,
        setup: setupCursorHover,
    })
    const colorIndicator = Box({
        className: `sidebar-chat-indicator`,
    });
    const downloadState = Stack({
        homogeneous: false,
        transition: 'slide_up_down',
        transitionDuration: 150,
        items: [
            ['api', ImageState('api', 'Calling API')],
            ['download', ImageState('downloading', 'Downloading image')],
            ['done', ImageState('done', 'Finished!')],
            ['error', ImageState('error', 'Error')],
        ]
    });
    const downloadIndicator = MarginRevealer({
        vpack: 'center',
        transition: 'slide_left',
        revealChild: true,
        child: downloadState,
    });
    const blockHeading = Box({
        hpack: 'fill',
        className: 'sidebar-waifu-content spacing-h-5',
        children: [
            ...taglist.map((tag) => CommandButton(tag)),
            Box({ hexpand: true }),
            downloadIndicator,
        ]
    });
    const blockImageActions = Box({
        className: 'sidebar-waifu-image-actions spacing-h-3',
        children: [
            Box({ hexpand: true }),
            ImageAction({
                name: 'Go to source',
                icon: 'link',
                action: () => execAsync(['xdg-open', `${blockImageData.source}`]).catch(print),
            }),
            ImageAction({
                name: 'Hoard',
                icon: 'save',
                action: () => execAsync(['bash', '-c', `mkdir -p ~/Pictures/waifus && cp ${imagePath} ~/Pictures/waifus`]).catch(print),
            }),
            ImageAction({
                name: 'Open externally',
                icon: 'open_in_new',
                action: () => execAsync(['xdg-open', `${imagePath}`]).catch(print),
            }),
        ]
    })
    const blockImage = Box({
        className: 'test',
        hpack: 'start',
        vertical: true,
        className: 'sidebar-waifu-image',
        homogeneous: true,
        children: [
            Revealer({
                transition: 'crossfade',
                revealChild: false,
                child: Box({
                    vertical: true,
                    children: [blockImageActions],
                })
            })
        ]
    })
    const blockImageRevealer = Revealer({
        transition: 'slide_down',
        transitionDuration: 150,
        revealChild: false,
        child: blockImage,
    });
    const thisBlock = Box({
        className: 'sidebar-chat-message',
        properties: [
            ['update', (imageData) => {
                blockImageData = imageData;
                const { status, signature, url, source, dominant_color, is_nsfw, width, height, tags } = blockImageData;
                if (status != 200) {
                    downloadState.shown = 'error';
                    return;
                }
                imagePath = `${GLib.get_user_cache_dir()}/ags/media/waifus/${signature}`;
                downloadState.shown = 'download';
                // Width allocation
                const widgetWidth = Math.min(Math.floor(waifuContent.get_allocated_width() * 0.75), width);
                blockImage.set_size_request(widgetWidth, Math.ceil(widgetWidth * height / width));
                // Start download
                const showImage = () => {
                    downloadState.shown = 'done';
                    blockImage.css = `background-image:url('${imagePath}');`;
                    blockImage.get_children()[0].revealChild = true;
                    Utils.timeout(blockImageRevealer.transitionDuration,
                        () => blockImageRevealer.revealChild = true
                    );
                    downloadIndicator._hide(downloadIndicator);
                }
                if (Gio.File.new_for_path(imagePath).query_exists(null)) showImage();
                else Utils.execAsync(['bash', '-c', `wget -O '${imagePath}' '${url}'`])
                    .then(showImage)
                    .catch(print);
                colorIndicator.css = `background-color: ${dominant_color};`;
            }],
        ],
        children: [
            colorIndicator,
            Box({
                vertical: true,
                className: 'spacing-v-5',
                children: [
                    blockHeading,
                    Box({
                        vertical: true,
                        children: [blockImageRevealer],
                    })
                ]
            })
        ],
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
        // Always scroll to bottom with new content
        const adjustment = scrolledWindow.get_vadjustment();
        adjustment.connect("changed", () => {
            adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size());
        })
    }
});

// const waifuTags = Box({
//     className: 'spacing-h-5',
//     children: [
//         Box({ hexpand: true }),
//         CommandButton('waifu'),
//         CommandButton('maid'),
//         CommandButton('uniform'),
//         CommandButton('oppai'),
//         CommandButton('selfies'),
//         CommandButton('marin-kitagawa'),
//         CommandButton('raiden-shogun'),
//         CommandButton('mori-calliope'),
//     ]
// });

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
        else if (text.startsWith('/test')) {
            const newImage = WaifuImage(['/test']);
            waifuContent.add(newImage);
            Utils.timeout(13, () => newImage._update({ // Needs timeout or inits won't make it
                // This is an image uploaded to my github repo
                status: 200,
                url: 'https://picsum.photos/400/600',
                signature: 0,
                source: 'https://picsum.photos/400/600',
                dominant_color: '#9392A6',
                is_nsfw: false,
                width: 300,
                height: 200,
                tags: ['/test'],
            }));
        }
    }
    else WaifuService.fetch(text);
}