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

export default (id) => {
    let files = Utils.exec(`bash -c "find ${dir} -type f | grep -E '.gif$|.jpg$|.jpeg$|.png$'"`);
    return Widget.Window({
        name: `wallpaperpicker${id}`,
        class_name: "wallpapers",
        monitor: id,
        anchor: ["top", "left", "right"],
        exclusivity: "normal",
        layer: "overlay",
        keymode: "on-demand",
        margins: [7],
        visible: false,
        child: Widget.Scrollable({
            vscroll: "never",
            hscroll: "always",
            class_name: 'wallpaperScroll',
            child: Widget.Box({
                class_name: 'wallpaperContainer',
                children: files.split("\n").filter(x => x !== "")
                    .map(path => ImagesList(path, id))
            }),
        }),
        setup: (self) => {
            self.keybind("Escape", () => closeEverything());
        },
    })
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
        child: Widget.Icon({
            class_name: 'wallpaperImage',
            size: 180,
            icon: (gif ? thumbnail : path),
        })
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
