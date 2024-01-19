const { Gdk, GdkPixbuf, Gio, GLib, Gtk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
import { SCREEN_HEIGHT, SCREEN_WIDTH } from '../../imports.js';
const { exec, execAsync } = Utils;
const { Box, Button, Label, Stack } = Widget;

import Wallpaper from '../../services/wallpaper.js';
import { setupCursorHover } from '../../lib/cursorhover.js';

const SWITCHWALL_SCRIPT_PATH = `${App.configDir}/scripts/color_generation/switchwall.sh`;
const WALLPAPER_ZOOM_SCALE = 1.1; // For scrolling when we switch workspace

export default (monitor = 0) => {
    let pixbuf = undefined;
    const wallpaperImage = Widget.DrawingArea({
        css: `transition: 1000ms cubic-bezier(0.1, 1, 0, 1);`,
        setup: (self) => {
            self.set_size_request(SCREEN_WIDTH, SCREEN_HEIGHT);
            self.on('draw', (widget, cr) => {
                if (!pixbuf) return;
                Gdk.cairo_set_source_pixbuf(cr, pixbuf, 0, 0);
                cr.paint();
            });
            self.hook(Wallpaper, (self) => {
                const wallPath = Wallpaper.get(monitor);
                if (!wallPath || wallPath === "") return;
                pixbuf = GdkPixbuf.Pixbuf.new_from_file(wallPath);
                
                const scale_x = SCREEN_WIDTH * WALLPAPER_ZOOM_SCALE / pixbuf.get_width();
                const scale_y = SCREEN_HEIGHT * WALLPAPER_ZOOM_SCALE / pixbuf.get_height();
                const scale_factor = Math.max(scale_x, scale_y);

                pixbuf = pixbuf.scale_simple(
                    Math.round(pixbuf.get_width() * scale_factor),
                    Math.round(pixbuf.get_height() * scale_factor),
                    GdkPixbuf.InterpType.BILINEAR
                );

                // pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(wallPath, SCREEN_WIDTH, SCREEN_HEIGHT);
                // console.log(pixbuf.get_width(), pixbuf.get_height())

                // pixbuf = GdkPixbuf.Pixbuf.new_from_file(wallPath);
                // console.log(pixbuf.get_width(), pixbuf.get_height())
                
                self.queue_draw();
            }, 'updated');
        }
        ,
    });
    const wallpaperPrompt = Box({
        hpack: 'center',
        vpack: 'center',
        vertical: true,
        className: 'spacing-v-10',
        children: [
            Label({
                hpack: 'center',
                className: 'txt-large',
                label: `No wallpaper loaded`,
            }),
            Button({
                hpack: 'center',
                className: 'btn-primary',
                label: `Select one`,
                setup: setupCursorHover,
                onClicked: (self) => Utils.execAsync([SWITCHWALL_SCRIPT_PATH]),
            }),
        ]
    });
    const stack = Stack({
        transition: 'crossfade',
        transitionDuration: 180,
        items: [
            ['image', wallpaperImage],
            ['prompt', wallpaperPrompt],
        ],
        setup: (self) => self
            .hook(Wallpaper, (self) => {
                const wallPath = Wallpaper.get(monitor);
                self.shown = ((wallPath && wallPath != "") ? 'image' : 'prompt');
            }, 'updated')
        ,
    })
    return stack;
    // return wallpaperImage;
}
