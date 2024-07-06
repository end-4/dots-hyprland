import PopupWindow from '../.widgethacks/popupwindow.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box, Window } = Widget;

//const b = Variable(false);
const dir = userOptions.wallpaper.path;
const scriptDir = `${App.configDir}/scripts/color_generation/switchwall.sh`;

/*
function updateFiles() {
    files.value = Utils.exec(`find ${dir} -type f | grep -E '.jpg$|.jpeg$|.png$|.gif$'`);
}

*/
//function OpenWallpaper() {
    //    return Widget.Button({
//        child: Widget.Icon({ icon: "starred" }),
//        onClicked: () => {
    //            updateFiles()
    //            b.value = !b.value
//            App.toggleWindow('wallpaper')
//        }
//    })
//}

// const PopupWindow = ({
//     name,
//     child,
//     showClassName = "",
//     hideClassName = "",
//     ...props
// }) => {
//     return Window({
//         name,
//         visible: false,
//         layer: 'overlay',
//         ...props,

//         // child: child,
//         child: Box({
//             setup: (self) => {
//                 self.keybind("Escape", () => closeEverything());
//                 if (showClassName != "" && hideClassName !== "") {
//                     self.hook(App, (self, currentName, visible) => {
//                         if (currentName === name) {
//                             self.toggleClassName(hideClassName, !visible);
//                         }
//                     });

//                     if (showClassName !== "" && hideClassName !== "")
//                         self.className = `${showClassName} ${hideClassName}`;
//                 }
//             },
//             child: child,
//         }),
//     });
// }

export default (id) => {
    let files = Utils.exec(`bash -c "find ${dir} -type f | grep -E '.gif$'"`);//|.jpg$|.jpeg$|.png$'"`);
    return PopupWindow({
        name: `wallpaperpicker${id}`,
        class_name: "wallpaper",
        monitor: id,
        anchor: ["top", "left", "right"],
        // anchor: ["left", "top", "bottom"],
        layer: "overlay",
        keymode: "on-demand",
        margins: [7],
        child: Widget.Scrollable({
            class_name: 'wallpaperScroll',
            hscroll: "never",
            vscroll: "always",
            child: Widget.Box({
                class_name: 'wallpaperContainer',
                children: files.split("\n").map(path => ImagesList(path, id))
            }),
        }),
        /* setup: (self) => {
            self.keybind("Escape", () => closeEverything());
        }, */
        setup: (self) => {
            autoWallpaper();
        },
    })
}

export function autoWallpaper() {
    if (userOptions.wallpaper.autoChange) {
        Utils.interval(userOptions.wallpaper.interval * 1000, () => {
            randomWallpaper();
        })
    }
}

function ImagesList(path, id) {
    let gif = path.endsWith(".gif");
    let thumbnail = `${path.substr(path.lastIndexOf(".") + 1, path.length)}`;
    // thumbnail = thumbnail.substr(0, thumbnail.lastIndexOf(".") - 1);
    // console.log(thumbnail);
    // thumbnail += `\x00icon\x1f${path}`;
    // console.log(thumbnail);
    return Widget.Button({
        class_name: 'wallpaperButton',
        onPrimaryClick: () => {
            App.closeWindow(`wallpaperpicker${id}`);
            setWallpaper(path);
        },
        setup : (self) => {
            Utils.idle(() => {
                self.css = `background-image: url("${path}");`;
            });
        },
    })
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
