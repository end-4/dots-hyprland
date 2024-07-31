import PopupWindow from '../.widgethacks/popupwindow.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import clickCloseRegion from '../.commonwidgets/clickcloseregion.js';
const { Gio, GLib, Gtk, GdkPixbuf, Gdk } = imports.gi;

const dir = userOptions.wallpaper.path;
const scriptDir = `${App.configDir}/scripts/color_generation/switchwall.sh`;

function ImagesList(path, monitor, nb) {
    if (!path || path.search("No such file or directory") != -1) return Widget.Label({
        class_name: 'wallpaperpicker-min',
        label: "Wallpaper folder empty or nonexistent. Please add files of type .png/.jpg/.jpeg/.gif or change the path in `~/.config/ags/user_options.js`.",
    });
    let basename = path.split("/").pop();
    // let variable = Variable("");
    let gif = basename.substr(basename.lastIndexOf(".") + 1, basename.length) == "gif";
    let variable = Variable(Widget.Label({
        //TODO find better way
        class_name: gif ? "wallpaperpicker-min icon-material txt-gigantic" : "wallpaperpicker-min",
        label: gif ? "gif_box" : "Image still loading",
    }));
    let child = variable.bind();
    return Widget.Box({
        class_name: 'wallpaperpicker-box',
        vertical: true,
        children: [
            Widget.Button({
                class_name: 'wallpaperpicker-button',
                child: Widget.Box({
                    class_name: 'wallpaperpicker-min',
                    child: child,
                }),
                onPrimaryClick: () => {
                    App.closeWindow(`wallpaperpicker${monitor}`);
                    setWallpaper(path);
                },
                setup: () => {
                    if (!gif) {
                        // Utils.idle(() => {
                        let timeout = 500;
                        Utils.timeout(nb * timeout, () => {
                            let pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 160, 90, false);
                            Utils.timeout(timeout / 2, () => {
                                let image = Gtk.Image.new_from_pixbuf(pixbuf);
                                variable.value = Widget.Box({
                                    hpack: 'center',
                                    child: image,
                                });
                            });
                        });
                    }
                },
            }),
            Widget.Label({
                class_name: "wallpaperpicker-label",
                label: basename,
                truncate: `middle`,
            }),
        ],
    })
}

const wallpaperScrollable = (id) => {
    const files = Utils.exec(`bash -c "find ${dir} -type f | grep -E '.gif$|.jpg$|.jpeg$|.png$'"`);
    let i = 0;
    return Widget.Box({
        class_name: 'wallpaperpicker-bg',
        child: Widget.Scrollable({
            class_name: 'wallpaperpicker-scroll',
            hexpand: true,
            hscroll: "always",
            vscroll: "never",
            child: Widget.Box({
                children: files.split("\n").map(path =>ImagesList(path, id, i++)),
            }),
        }),
    });
};

export const WallpaperPicker = (id) => {
    return PopupWindow({
        name: `wallpaperpicker${id}`,
        monitor: id,
        anchor: ["top", "left", "right"],
        layer: "overlay",
        keymode: "on-demand",
        child: Widget.Box({
            vertical: true,
            children: [
                wallpaperScrollable(id),
                clickCloseRegion({ name: `wallpaperpicker` , fillMonitor: `vertical`}),
            ],
        }),
    })
}

export function autoWallpaper() {
    let interval = userOptions.wallpaper.interval * 1000;
    if (userOptions.wallpaper.autoChange) {
        Utils.timeout(interval, () => {
            Utils.interval(interval, () => {
                randomWallpaper();
            })
        })
    }
}

function setWallpaper(path) {
    let smartflag = userOptions.wallpaper.smart ? '--smart' : '';
    let popupflag = userOptions.wallpaper.popup ? '' : '--no-popup';
    Utils.execAsync(['bash', '-c', `sh "${scriptDir}" "${path}" "${smartflag}" "${popupflag}"`]).catch(print);
}

globalThis['randomWallpaper'] = () => {
    let path= Utils.exec(`bash -c "find ${dir} -type f | grep -E '.gif$|.jpg$|.jpeg$|.png$' | shuf -n 1"`);
    setWallpaper(path);
}
