const { Gdk, GdkPixbuf, Gio, GLib, Gtk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
import { SCREEN_HEIGHT, SCREEN_WIDTH } from '../../variables.js';
const { exec, execAsync } = Utils;
const { Box, Button, Label, Stack } = Widget;
import Hyprland from 'resource:///com/github/Aylur/ags/service/hyprland.js';

import Wallpaper from '../../services/wallpaper.js';
import { setupCursorHover } from '../.widgetutils/cursorhover.js';
import { clamp } from '../.miscutils/mathfuncs.js';

const DISABLE_AGS_WALLPAPER = true;

const SWITCHWALL_SCRIPT_PATH = `${App.configDir}/scripts/color_generation/switchwall.sh`;
const WALLPAPER_ZOOM_SCALE = 1.25; // For scrolling when we switch workspace
const MAX_WORKSPACES = 10;

const WALLPAPER_OFFSCREEN_X = (WALLPAPER_ZOOM_SCALE - 1) * SCREEN_WIDTH;
const WALLPAPER_OFFSCREEN_Y = (WALLPAPER_ZOOM_SCALE - 1) * SCREEN_HEIGHT;


export default (monitor = 0) => {
    const wallpaperImage = Widget.DrawingArea({
        attribute: {
            pixbuf: undefined,
            workspace: 1,
            sideleft: 0,
            sideright: 0,
            updatePos: (self) => {
                self.setCss(`font-size: ${self.attribute.workspace - self.attribute.sideleft + self.attribute.sideright}px;`)
            },
        },
        className: 'bg-wallpaper-transition',
        setup: (self) => {
            self.set_size_request(SCREEN_WIDTH, SCREEN_HEIGHT);
            self
                // TODO: reduced updates using timeouts to reduce lag
                // .hook(Hyprland.active.workspace, (self) => {
                //     self.attribute.workspace = Hyprland.active.workspace.id
                //     self.attribute.updatePos(self);
                // })
                // .hook(App, (box, name, visible) => { // Update on open
                //     if (self.attribute[name] === undefined) return;
                //     self.attribute[name] = (visible ? 1 : 0);
                //     self.attribute.updatePos(self);
                // })
                .on('draw', (self, cr) => {
                    if (!self.attribute.pixbuf) return;
                    const styleContext = self.get_style_context();
                    const workspace = styleContext.get_property('font-size', Gtk.StateFlags.NORMAL);
                    // Draw
                    Gdk.cairo_set_source_pixbuf(cr, self.attribute.pixbuf,
                        -(WALLPAPER_OFFSCREEN_X / (MAX_WORKSPACES + 1) * (clamp(workspace, 0, MAX_WORKSPACES + 1))),
                        -WALLPAPER_OFFSCREEN_Y / 2);
                    cr.paint();
                })
                .hook(Wallpaper, (self) => {
                    if (DISABLE_AGS_WALLPAPER) return;
                    const wallPath = Wallpaper.get(monitor);
                    if (!wallPath || wallPath === "") return;
                    self.attribute.pixbuf = GdkPixbuf.Pixbuf.new_from_file(wallPath);

                    const scale_x = SCREEN_WIDTH * WALLPAPER_ZOOM_SCALE / self.attribute.pixbuf.get_width();
                    const scale_y = SCREEN_HEIGHT * WALLPAPER_ZOOM_SCALE / self.attribute.pixbuf.get_height();
                    const scale_factor = Math.max(scale_x, scale_y);

                    self.attribute.pixbuf = self.attribute.pixbuf.scale_simple(
                        Math.round(self.attribute.pixbuf.get_width() * scale_factor),
                        Math.round(self.attribute.pixbuf.get_height() * scale_factor),
                        GdkPixbuf.InterpType.BILINEAR
                    );
                    self.queue_draw();
                }, 'updated');
            ;
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
                justification: 'center',
                className: 'txt-large',
                label: `No wallpaper loaded.\nAn image ≥ ${SCREEN_WIDTH * WALLPAPER_ZOOM_SCALE} × ${SCREEN_HEIGHT * WALLPAPER_ZOOM_SCALE} is recommended.`,
            }),
            Button({
                hpack: 'center',
                className: 'btn-primary',
                label: `Select one`,
                setup: setupCursorHover,
                onClicked: (self) => Utils.execAsync([SWITCHWALL_SCRIPT_PATH]).catch(print),
            }),
        ]
    });
    const stack = Stack({
        transition: 'crossfade',
        transitionDuration: userOptions.animations.durationLarge,
        children: {
            'disabled': Box({}),
            'image': wallpaperImage,
            'prompt': wallpaperPrompt,
        },
        setup: (self) => self
            .hook(Wallpaper, (self) => {
                if(DISABLE_AGS_WALLPAPER) {
                    self.shown = 'disabled';
                    return;
                }
                const wallPath = Wallpaper.get(monitor);
                self.shown = ((wallPath && wallPath != "") ? 'image' : 'prompt');
            }, 'updated')
        ,
    })
    return stack;
    // return wallpaperImage;
}
