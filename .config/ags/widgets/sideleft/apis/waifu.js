const { Gdk, GdkPixbuf, Gio, GLib, Gtk, Pango } = imports.gi;
import { App, Utils, Widget } from '../../../imports.js';
const { Box, Button, Entry, EventBox, Icon, Label, Overlay, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from "../../../lib/materialicon.js";
import { MarginRevealer } from '../../../lib/advancedwidgets.js';
import { setupCursorHover, setupCursorHoverInfo } from "../../../lib/cursorhover.js";
import WaifuService from '../../../services/waifus.js';

const IMAGE_REVEAL_DELAY = 13; // Some wait for inits n other weird stuff

// Create cache folder and clear pics from previous session
Utils.exec(`bash -c 'mkdir -p ${GLib.get_user_cache_dir()}/ags/media/waifus'`);
Utils.exec(`bash -c 'rm ${GLib.get_user_cache_dir()}/ags/media/waifus/*'`);

export function fileExists(filePath) {
    let file = Gio.File.new_for_path(filePath);
    return file.query_exists(null);
}

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
    const ImageState = (icon, name) => Box({
        className: 'spacing-h-5 txt',
        children: [
            Box({ hexpand: true }),
            Label({
                className: 'sidebar-waifu-txt txt-smallie',
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
    const blockImageActions = Revealer({
        transition: 'crossfade',
        revealChild: false,
        child: Box({
            vertical: true,
            children: [
                Box({
                    className: 'sidebar-waifu-image-actions spacing-h-3',
                    children: [
                        Box({ hexpand: true }),
                        ImageAction({
                            name: 'Go to source',
                            icon: 'link',
                            action: () => execAsync(['xdg-open', `${thisBlock._imageData.source}`]).catch(print),
                        }),
                        ImageAction({
                            name: 'Hoard',
                            icon: 'save',
                            action: () => execAsync(['bash', '-c', `mkdir -p ~/Pictures/waifus && cp ${thisBlock._imagePath} ~/Pictures/waifus`]).catch(print),
                        }),
                        ImageAction({
                            name: 'Open externally',
                            icon: 'open_in_new',
                            action: () => execAsync(['xdg-open', `${thisBlock._imagePath}`]).catch(print),
                        }),
                    ]
                })
            ],
        })
    })
    const blockImage = Widget.DrawingArea({
        className: 'sidebar-waifu-image',
    });
    // const blockImage = Box({});
    // const blockImage = Image({
    //     hpack: 'start',
    //     vertical: true,
    //     className: 'sidebar-waifu-image',
    //     // homogeneous: true,
    // })
    const blockImageRevealer = Revealer({
        transition: 'slide_down',
        transitionDuration: 150,
        revealChild: false,
        child: Overlay({
            child: Box({
                homogeneous: true,
                className: 'sidebar-waifu-image',
                children: [blockImage],
            }),
            overlays: [blockImageActions],
        }),
    });
    const thisBlock = Box({
        className: 'sidebar-chat-message',
        properties: [
            ['imagePath', ''],
            ['imageData', ''],
            ['update', (imageData, force = false) => {
                thisBlock._imageData = imageData;
                const { status, signature, url, extension, source, dominant_color, is_nsfw, width, height, tags } = thisBlock._imageData;
                if (status != 200) {
                    downloadState.shown = 'error';
                    return;
                }
                thisBlock._imagePath = `${GLib.get_user_cache_dir()}/ags/media/waifus/${signature}${extension}`;
                downloadState.shown = 'download';
                // Width/height
                const widgetWidth = Math.min(Math.floor(waifuContent.get_allocated_width() * 0.85), width);
                const widgetHeight = Math.ceil(widgetWidth * height / width);
                blockImage.set_size_request(widgetWidth, widgetHeight);
                const showImage = () => {
                    downloadState.shown = 'done';
                    const pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(thisBlock._imagePath, widgetWidth, widgetHeight, false);

                    blockImage.set_size_request(widgetWidth, widgetHeight);
                    blockImage.connect("draw", (widget, cr) => {
                        const borderRadius = widget.get_style_context().get_property('border-radius', Gtk.StateFlags.NORMAL);

                        // Draw a rounded rectangle
                        cr.arc(borderRadius, borderRadius, borderRadius, Math.PI, 1.5 * Math.PI);
                        cr.arc(widgetWidth - borderRadius, borderRadius, borderRadius, 1.5 * Math.PI, 2 * Math.PI);
                        cr.arc(widgetWidth - borderRadius, widgetHeight - borderRadius, borderRadius, 0, 0.5 * Math.PI);
                        cr.arc(borderRadius, widgetHeight - borderRadius, borderRadius, 0.5 * Math.PI, Math.PI);
                        cr.closePath();
                        cr.clip();

                        // Paint image as bg
                        Gdk.cairo_set_source_pixbuf(cr, pixbuf, 0, 0);
                        cr.paint();
                    });

                    // Reveal stuff
                    Utils.timeout(IMAGE_REVEAL_DELAY, () => {
                        blockImageRevealer.revealChild = true;
                    })
                    Utils.timeout(IMAGE_REVEAL_DELAY + blockImageRevealer.transitionDuration,
                        () => blockImageActions.revealChild = true
                    );
                    downloadIndicator._hide();
                }
                // Show
                if (!force && fileExists(thisBlock._imagePath)) showImage();
                else Utils.execAsync(['bash', '-c', `wget -O '${thisBlock._imagePath}' '${url}'`])
                    .then(showImage)
                    .catch(print);
                blockHeading.get_children().forEach((child) => {
                    child.setCss(`border-color: ${dominant_color};`);
                })
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
                        hpack: 'start',
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

const waifuTags = Revealer({
    revealChild: false,
    transition: 'crossfade',
    transitionDuration: 150,
    child: Box({
        className: 'spacing-h-5',
        children: [
            Scrollable({
                vscroll: 'never',
                hscroll: 'automatic',
                hexpand: true,
                child: Box({
                    className: 'spacing-h-5',
                    children: [
                        CommandButton('waifu'),
                        CommandButton('maid'),
                        CommandButton('uniform'),
                        CommandButton('oppai'),
                        CommandButton('selfies'),
                        CommandButton('marin-kitagawa'),
                        CommandButton('raiden-shogun'),
                        CommandButton('mori-calliope'),
                    ]
                })
            }),
            Box({ className: 'separator-line' }),
        ]
    })
});

export const waifuCommands = Box({
    className: 'spacing-h-5',
    setup: (self) => {
        self.pack_end(CommandButton('/clear'), false, false, 0);
        self.pack_start(Button({
            className: 'sidebar-chat-chip-toggle',
            setup: setupCursorHover,
            label: 'Tags →',
            onClicked: () => {
                waifuTags.revealChild = !waifuTags.revealChild;
            }
        }), false, false, 0);
        self.pack_start(waifuTags, true, true, 0);
    }
});

const clearChat = () => {
    const kids = waifuContent.get_children();
    for (let i = 0; i < kids.length; i++) {
        const child = kids[i];
        if (child) child.destroy();
    }
}

export const sendMessage = (text) => {
    // Do something on send
    // Commands
    if (text.startsWith('/')) {
        if (text.startsWith('/clear')) clearChat();
        else if (text.startsWith('/test')) {
            const newImage = WaifuImage(['/test']);
            waifuContent.add(newImage);
            Utils.timeout(IMAGE_REVEAL_DELAY, () => newImage._update({ // Needs timeout or inits won't make it
                // This is an image uploaded to my github repo
                status: 200,
                url: 'https://picsum.photos/400/600',
                extension: '',
                signature: 0,
                source: 'https://picsum.photos/400/600',
                dominant_color: '#9392A6',
                is_nsfw: false,
                width: 300,
                height: 200,
                tags: ['/test'],
            }, true));
        }
    }
    else WaifuService.fetch(text);
}