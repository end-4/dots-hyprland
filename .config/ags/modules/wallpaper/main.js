import PopupWindow from '../.widgethacks/popupwindow.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Gio, GLib, Gtk, GdkPixbuf, Gdk } = imports.gi;

const dir = userOptions.wallpaper.path;
const scriptDir = `${App.configDir}/scripts/color_generation/switchwall.sh`;

// function updateFiles() {
//     files.value = Utils.exec(`find ${dir} -type f | grep -E '.jpg$|.jpeg$|.png$|.gif$'`);
// }

export const WallpaperPicker = (id) => {
    let files = Utils.exec(`bash -c "find ${dir} -type f | grep -E '.jpg$|.jpeg$|.png$ '"`);
    console.log(Object.keys(Gdk));
    return PopupWindow({
        name: `wallpaperpicker${id}`,
        class_name: "wallpaper",
        monitor: id,
        anchor: ["top", "left", "right"],
        layer: "overlay",
        keymode: "on-demand",
        margins: [7],
        child: Widget.Scrollable({
            class_name: 'wallpaperScroll',
            hexpand: true,
            hscroll: "always",
            vscroll: "never",
            child: Widget.Box({
                class_name: 'wallpaperContainer',
                children: files.split("\n").map(path => ImagesList(path, id))
            }),
        }),
    })
}

function ImagesList(path, id) {
    let basename = path.split("/").pop();
    let image;// = Gtk.Image.new();
    let pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 150, 150, false);
    // image = Utils.idle(() => {
        // if (basename.lastIndexOf(".") + 1 == "gif") {
        //     let animation = GdkPixbuf.PixbufAnimation.new_from_file(path);
        //     image = Gtk.Image.new_from_animation(animation);
        // } else {
            // image = Gtk.Image.new_from_pixbuf(pixbuf);
        // }
    // });
    // Gtk.Widget.set_name(image, 'wallpaperImage');
    // console.log("Image: ", image);
    return Widget.Box({
        vertical: true,
        children: [
            Widget.Button({
                class_name: 'wallpaperButton',
                child: Widget.Icon({
                    class_name: 'wallpaperIcon',
                    icon: pixbuf,
                    size: 150,
                }),
                // child: Widget.Box({
                //     child: image,
                //      //Widget.Label({label: "No Image",}),
                //     // css: 'max-width: 16rem, max-height: 9rem;',
                // }),
                onPrimaryClick: () => {
                    App.closeWindow(`wallpaperpicker${id}`);
                    setWallpaper(path);
                },
                // setup : (self) => {
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
                label: `${basename.length < 30 ? basename : basename.substr(0, 25) +
                    " (...) " + basename.substr(basename.lastIndexOf("."), basename.length)}`,
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
    console.log(`sh ${scriptDir} ${path} ${smartflag} ${popupflag}`);
    Utils.execAsync(['bash', '-c', `sh "${scriptDir}" "${path}" "${smartflag}" "${popupflag}"`]).catch(print);
}

globalThis['randomWallpaper'] = () => {
    let path= Utils.exec(`bash -c "find ${dir} -type f | grep -E '.gif$|.jpg$|.jpeg$|.png$|.svg' | shuf -n 1"`);
    setWallpaper(path);
}
