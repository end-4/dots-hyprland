import PopupWindow from '../.widgethacks/popupwindow.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import clickCloseRegion from '../.commonwidgets/clickcloseregion.js';
const { Gio, GLib, Gtk, GdkPixbuf, Gdk } = imports.gi;

const dir = userOptions.wallpaper.path;
const scriptDir = `${App.configDir}/scripts/color_generation/switchwall.sh`;
// const files = Variable("");
// const children = Variable([ Widget.Label({ label: `Files still loading` }), Widget.Label({ label: 'test' }) ]);
const files = Utils.exec(`bash -c "find ${dir} -type f | grep -E '.jpg$|.jpeg$|.png$'"`);
// let children = [ Widget.Label({ label: `Files still loading` }), Widget.Label({ label: 'test' }) ];
// children = await files.split("\n").map(path => ImagesList(path, 0));

function updateFiles(id) {
    // files.value = Utils.exec(`bash -c "find ${dir} -type f | grep -E '.jpg$|.jpeg$|.png$'"`);
    // children.value = files.split("\n").map(path => ImagesList(path, id));
}

function ImagesList(path, monitor, timeout) {
    if (!path) return Widget.Label({
        label: "Folder empty",
    });
    let basename = path.split("/").pop();
    // let image;
    // if (basename.lastIndexOf(".") + 1 == "gif") {
    //     let animation = GdkPixbuf.PixbufAnimation.new_from_file(path);
    //     image = Gtk.Image.new_from_animation(animation);
    // } else {
    //     let pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 160, 90, false);
    //     image = Gtk.Image.new_from_pixbuf(pixbuf);
    // }
    let variable = Variable(Widget.Label({
        //TODO find better way
        class_name: 'wallpaperPlaceholder',
        label: "Image still loading",
    }));
    let child = variable.bind();
    // Utils.execAsync((child, path) => {
    //     let pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 160, 90, false);
    //     let image = Gtk.Image.new_from_pixbuf(pixbuf);
    //     // child.value = Widget.Box({
    //     //     hpack: 'center',
    //     //     child: image,
    //     // });
    // });
    return Widget.Box({
        class_name: 'wallpaperBox',
        vertical: true,
        children: [
            Widget.Button({
                class_name: 'wallpaperButton',
                child: Widget.Box({
                    class_name: 'wallpaperImageBox',
                    child: child,
                }),
                // child: Widget.Box({
                //     hpack: 'center',
                //     child: image,
                //      //Widget.Label({label: "No Image",}),
                // }),
                onPrimaryClick: () => {
                    App.closeWindow(`wallpaperpicker${monitor}`);
                    setWallpaper(path);
                },
                setup: (self) => {
                    // Utils.idle(() => {
                    Utils.timeout(timeout * 500, () => {
                        console.log(path);
                        let pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 160, 90, false);
                        let image = Gtk.Image.new_from_pixbuf(pixbuf);
                        variable.value = Widget.Box({
                            hpack: 'center',
                            child: image,
                        });
                        // child.value = Widget.Label({label: "WOOrking yay",});
                    });
                    // });
                    // let test = self;
                    // Utils.idle((test) => {
                    //     if (basename.lastIndexOf(".") + 1 == "gif") {
                    //         let animation = GdkPixbuf.PixbufAnimation.new_from_file(path);
                    //         let image = Gtk.Image.new_from_animation(animation);
                    //     } else {
                    //         let pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 160, 90, false);
                    //         // Gtk.Image.set_from_pixbuf(image, pixbuf);
                    //         let image = Gtk.Image.new_from_pixbuf(pixbuf);
                    //     }
                    //     self.child = image;
                    // });
                    // let image = gtk_image_new_from_file(path);
                    // Utils.idle(() => {
                    //     self.css = `background-image: url("${path}");`;
                    // });
                },
            }),
            Widget.Label({
                class_name: 'wallpaperLabel',
                label: basename,
                truncate: `middle`,
            }),
        ],
    })
}

const wallpaperScrollable = (id) => {
    let i = 0;
    // Utils.idle(updateFiles(id));
    // arr = files.split("\n");
    // children = (arr, i) => {

    // }
    return Widget.Box({
        class_name: 'wallpaperContainer',
        child: Widget.Scrollable({
            class_name: 'wallpaperScroll',
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
    // Utils.idle(updateFiles(id));
    // console.log(Object.keys(Gdk));
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

// globalThis['test'] = () => {
//     console.log("value" + files.value);
//     return "value" + files.value;
// }

globalThis['updateFiles'] = () => {
    files.value = Utils.exec(`bash -c "find ${dir} -type f | grep -E '.jpg$|.jpeg$|.png$'"`);
}

globalThis['randomWallpaper'] = () => {
    let path= Utils.exec(`bash -c "find ${dir} -type f | grep -E '.gif$|.jpg$|.jpeg$|.png$' | shuf -n 1"`);
    setWallpaper(path);
}
