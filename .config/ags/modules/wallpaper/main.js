import PopupWindow from '../.widgethacks/popupwindow.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import clickCloseRegion from '../.commonwidgets/clickcloseregion.js';
const { Gio, GLib, Gtk, GdkPixbuf, Gdk } = imports.gi;

const dir = userOptions.wallpaper.path;
const scriptDir = `${App.configDir}/scripts/color_generation/switchwall.sh`;

// function updateFiles() {
//     files.value = Utils.exec(`find ${dir} -type f | grep -E '.jpg$|.jpeg$|.png$|.gif$'`);
// }

const wallpaperScrollable = (id, files) => {
    return Widget.Box({
        class_name: 'wallpaperContainer',
        child: Widget.Scrollable({
            class_name: 'wallpaperScroll',
            hexpand: true,
            hscroll: "always",
            vscroll: "never",
            child: Widget.Box({
                children: files.split("\n").map(path => ImagesList(path, id))
            }),
        }),
    });
};

export const WallpaperPicker = (id) => {
    let files = Utils.exec(`bash -c "find ${dir} -type f | grep -E '.jpg$|.jpeg$|.png$ '"`);
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
                wallpaperScrollable(id, files),
                clickCloseRegion({ name: `wallpaperpicker` , fillMonitor: `vertical`}),
            ],
        }),
    })
}

function ImagesList(path, id) {
    let basename = path.split("/").pop();
    // let image = Gtk.Image.new_from_file(path);
    // let pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(path, 160, 90);
    // let image = Gtk.Image.new_from_pixbuf(pixbuf);
    let image;
    if (basename.lastIndexOf(".") + 1 == "gif") {
        let animation = GdkPixbuf.PixbufAnimation.new_from_file(path);
        image = Gtk.Image.new_from_animation(animation);
    } else {
        let pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 160, 90, false);
        image = Gtk.Image.new_from_pixbuf(pixbuf);
    }
    // console.log("Image: ", image);
    return Widget.Box({
        class_name: 'wallpaperBox',
        vertical: true,
        children: [
            Widget.Button({
                class_name: 'wallpaperButton',
                // child: Widget.Icon({
                //     class_name: 'wallpaperIcon',
                //     icon: pixbuf,
                //     size: 150,
                // }),
                child: Widget.Box({
                    hpack: 'center',
                    child: image,
                     //Widget.Label({label: "No Image",}),
                }),
                onPrimaryClick: () => {
                    App.closeWindow(`wallpaperpicker${id}`);
                    setWallpaper(path);
                },
                // setup: (self) => {
                //     let test = self;
                //     Utils.idle((test) => {
                //         if (basename.lastIndexOf(".") + 1 == "gif") {
                //             let animation = GdkPixbuf.PixbufAnimation.new_from_file(path);
                //             let image = Gtk.Image.new_from_animation(animation);
                //         } else {
                //             let pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 160, 90, false);
                //             // Gtk.Image.set_from_pixbuf(image, pixbuf);
                //             let image = Gtk.Image.new_from_pixbuf(pixbuf);
                //         }
                //         self.child = image;
                //     });
                //     // let image = gtk_image_new_from_file(path);
                //     // Utils.idle(() => {
                //     //     self.css = `background-image: url("${path}");`;
                //     // });
                // },
            }),
            Widget.Label({
                class_name: 'wallpaperLabel',
                label: basename,
                truncate: `middle`,
                justification: 'center',
            }),
        ],
    })
}

export function autoWallpaper() {
    if (userOptions.wallpaper.autoChange) {
        Utils.interval(userOptions.wallpaper.interval * 1000, () => {
            randomWallpaper();
        })
    }
}

function setWallpaper(path) {
    let smartflag = userOptions.wallpaper.smart ? '--smart' : '';
    let popupflag = userOptions.wallpaper.popup ? '' : '--no-popup';
    // console.log(`sh ${scriptDir} ${path} ${smartflag} ${popupflag}`);
    Utils.execAsync(['bash', '-c', `sh "${scriptDir}" "${path}" "${smartflag}" "${popupflag}"`]).catch(print);
}

globalThis['randomWallpaper'] = () => {
    let path= Utils.exec(`bash -c "find ${dir} -type f | grep -E '.gif$|.jpg$|.jpeg$|.png$|.svg' | shuf -n 1"`);
    setWallpaper(path);
}
