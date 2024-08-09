// TODO: execAsync(['identify', '-format', '{"w":%w,"h":%h}', imagePath])
// to detect img dimensions

const { Gdk, GdkPixbuf, Gio, GLib, Gtk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, Label, Overlay, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { fileExists } from '../../.miscutils/files.js';
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { MarginRevealer } from '../../.widgethacks/advancedrevealers.js';
import { setupCursorHover, setupCursorHoverInfo } from '../../.widgetutils/cursorhover.js';
import WaifuService from '../../../services/waifus.js';
import { darkMode } from '../../.miscutils/system.js';
import { chatEntry } from '../apiwidgets.js';

async function getImageViewerApp(preferredApp) {
    Utils.execAsync(['bash', '-c', `command -v ${preferredApp}`])
        .then((output) => {
            if (output != '') return preferredApp;
            else return 'xdg-open';
        })
        .catch(print);
}

const IMAGE_REVEAL_DELAY = 13; // Some wait for inits n other weird stuff
const IMAGE_VIEWER_APP = getImageViewerApp(userOptions.apps.imageViewer); // Gnome's image viewer cuz very comfortable zooming
const USER_CACHE_DIR = GLib.get_user_cache_dir();

// Create cache folder and clear pics from previous session
Utils.exec(`bash -c 'mkdir -p ${USER_CACHE_DIR}/ags/media/waifus'`);
Utils.exec(`bash -c 'rm ${USER_CACHE_DIR}/ags/media/waifus/*'`);

const CommandButton = (command) => Button({
    className: 'sidebar-chat-chip sidebar-chat-chip-action txt txt-small',
    onClicked: () => sendMessage(command),
    setup: setupCursorHover,
    label: command,
});

export const waifuTabIcon = Box({
    hpack: 'center',
    children: [
        MaterialIcon('photo', 'norm'),
    ]
});

const WaifuInfo = () => {
    const waifuLogo = Label({
        hpack: 'center',
        className: 'sidebar-chat-welcome-logo',
        label: 'photo',
    })
    return Box({
        vertical: true,
        vexpand: true,
        className: 'spacing-v-15',
        children: [
            waifuLogo,
            Label({
                className: 'txt txt-title-small sidebar-chat-welcome-txt',
                wrap: true,
                justify: Gtk.Justification.CENTER,
                label: 'Waifus',
            }),
            Box({
                className: 'spacing-h-5',
                hpack: 'center',
                children: [
                    Label({
                        className: 'txt-smallie txt-subtext',
                        wrap: true,
                        justify: Gtk.Justification.CENTER,
                        label: 'Powered by waifu.im + other APIs',
                    }),
                    Button({
                        className: 'txt-subtext txt-norm icon-material',
                        label: 'info',
                        tooltipText: 'Type tags for a random pic.\nNSFW content will not be returned unless\nyou explicitly request such a tag.\n\nDisclaimer: Not affiliated with the providers\nnor responsible for any of their content.',
                        setup: setupCursorHoverInfo,
                    }),
                ]
            }),
        ]
    });
}

const waifuWelcome = Box({
    vexpand: true,
    homogeneous: true,
    child: Box({
        className: 'spacing-v-15',
        vpack: 'center',
        vertical: true,
        children: [
            WaifuInfo(),
        ]
    })
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
    const downloadState = Stack({
        homogeneous: false,
        transition: 'slide_up_down',
        transitionDuration: userOptions.animations.durationSmall,
        children: {
            'api': ImageState('api', 'Calling API'),
            'download': ImageState('downloading', 'Downloading image'),
            'done': ImageState('done', 'Finished!'),
            'error': ImageState('error', 'Error'),
            'notfound': ImageState('error', 'Not found!'),
        },
    });
    const downloadIndicator = MarginRevealer({
        vpack: 'center',
        transition: 'slide_left',
        revealChild: true,
        child: downloadState,
    });
    const blockHeading = Box({
        hpack: 'fill',
        className: 'spacing-h-5',
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
                            action: () => execAsync(['xdg-open', `${thisBlock.attribute.imageData.source}`]).catch(print),
                        }),
                        ImageAction({
                            name: 'Hoard',
                            icon: 'save',
                            action: (self) => {
                                execAsync(['bash', '-c', `mkdir -p $(xdg-user-dir PICTURES)/homework${thisBlock.attribute.isNsfw ? '/🌶️' : ''} && cp ${thisBlock.attribute.imagePath} $(xdg-user-dir PICTURES)/homework${thisBlock.attribute.isNsfw ? '/🌶️/' : ''}`])
                                    .then(() => self.label = 'done')
                                    .catch(print);
                            },
                        }),
                        ImageAction({
                            name: 'Open externally',
                            icon: 'open_in_new',
                            action: () => execAsync([IMAGE_VIEWER_APP, `${thisBlock.attribute.imagePath}`]).catch(print),
                        }),
                    ]
                })
            ],
        })
    })
    const blockImage = Widget.DrawingArea({
        className: 'sidebar-waifu-image',
    });
    const blockImageRevealer = Revealer({
        transition: 'slide_down',
        transitionDuration: userOptions.animations.durationLarge,
        revealChild: false,
        child: Box({
            className: 'margin-top-5',
            children: [Overlay({
                child: Box({
                    homogeneous: true,
                    className: 'sidebar-waifu-image',
                    children: [blockImage],
                }),
                overlays: [blockImageActions],
            })]
        }),
    });
    const thisBlock = Box({
        className: 'sidebar-chat-message',
        attribute: {
            'imagePath': '',
            'isNsfw': false,
            'imageData': '',
            'update': (imageData, force = false) => {
                thisBlock.attribute.imageData = imageData;
                const { status, signature, url, extension, source, dominant_color, is_nsfw, width, height, tags } = thisBlock.attribute.imageData;
                thisBlock.attribute.isNsfw = is_nsfw;
                if (status == 404) {
                    downloadState.shown = 'notfound';
                    return;
                }
                if (status != 200) {
                    downloadState.shown = 'error';
                    return;
                }
                thisBlock.attribute.imagePath = `${USER_CACHE_DIR}/ags/media/waifus/${signature}${extension}`;
                downloadState.shown = 'download';
                // Width/height
                const widgetWidth = Math.min(Math.floor(waifuContent.get_allocated_width() * 0.85), width);
                const widgetHeight = Math.ceil(widgetWidth * height / width);
                blockImage.set_size_request(widgetWidth, widgetHeight);
                const showImage = () => {
                    downloadState.shown = 'done';
                    const pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(thisBlock.attribute.imagePath, widgetWidth, widgetHeight);
                    // const pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(thisBlock.attribute.imagePath, widgetWidth, widgetHeight, false);

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
                    downloadIndicator.attribute.hide();
                }
                // Show
                if (!force && fileExists(thisBlock.attribute.imagePath)) showImage();
                else Utils.execAsync(['bash', '-c', `wget -O '${thisBlock.attribute.imagePath}' '${url}'`])
                    .then(showImage)
                    .catch(print);
                thisBlock.css = `background-color: mix(${darkMode.value ? 'black' : 'white'}, ${dominant_color}, 0.97);`;
            },
        },
        children: [
            Box({
                vertical: true,
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
    attribute: {
        'map': new Map(),
    },
    setup: (self) => self
        .hook(WaifuService, (box, id) => {
            if (id === undefined) return;
            const newImageBlock = WaifuImage(WaifuService.queries[id]);
            box.add(newImageBlock);
            box.show_all();
            box.attribute.map.set(id, newImageBlock);
        }, 'newResponse')
        .hook(WaifuService, (box, id) => {
            if (id === undefined) return;
            const data = WaifuService.responses[id];
            if (!data) return;
            const imageBlock = box.attribute.map.get(id);
            imageBlock?.attribute.update(data);
        }, 'updateResponse')
    ,
});

export const waifuView = Scrollable({
    className: 'sidebar-chat-viewport',
    vexpand: true,
    child: Box({
        vertical: true,
        children: [
            waifuWelcome,
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
            if (!chatEntry.hasFocus) return;
            adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size());
        })
    }
});

const waifuTags = Revealer({
    revealChild: false,
    transition: 'crossfade',
    transitionDuration: userOptions.animations.durationLarge,
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

const clearChat = () => { // destroy!!
    waifuContent.attribute.map.forEach((value, key, map) => {
        value.destroy();
        value = null;
    });
}

function newSimpleImageCall(name, url, width, height, dominantColor = '#9392A6') {
    const timeSinceEpoch = Date.now();
    const newImage = WaifuImage([`/${name}`]);
    waifuContent.add(newImage);
    waifuContent.attribute.map.set(timeSinceEpoch, newImage);
    Utils.timeout(IMAGE_REVEAL_DELAY, () => newImage?.attribute.update({
        status: 200,
        url: url,
        extension: '',
        signature: timeSinceEpoch,
        source: url,
        dominant_color: dominantColor,
        is_nsfw: false,
        width: width,
        height: height,
        tags: [`/${name}`],
    }, true));
}

export const sendMessage = (text) => {
    // Commands
    if (text.startsWith('/')) {
        if (text.startsWith('/clear')) clearChat();
        else if (text.startsWith('/test'))
            newSimpleImageCall('test', 'https://picsum.photos/600/400', 300, 200);
        else if (text.startsWith('/chino'))
            newSimpleImageCall('chino', 'https://chino.pages.dev/chino', 300, 400, '#B2AEF3');
        else if (text.startsWith('/place'))
            newSimpleImageCall('place', 'https://placewaifu.com/image/400/600', 400, 600, '#F0A235');

    }
    else WaifuService.fetch(text);
}
