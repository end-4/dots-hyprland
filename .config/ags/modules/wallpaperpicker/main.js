//const b = Variable(false);
const dir = userOptions.wallpaper.path;
const scriptDir = `${App.configDir}/scripts/switchwall.sh`;

/*
function updateFiles() {
    files.value = Utils.exec(`find ${dir} -type f | grep -E '.jpg$|.jpeg$|.png$|.gif$'`);
}
*/

function setWallpaper(path) {
    Utils.execAsync(['bash', '-c', `sh ${scriptDir} ${path}`]).catch(print);
}

function closeWindow() {
    App.closeWindow('wallpaper')
    files.value = ""
}

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

export const Wallpaperpicker = (monitor = 0) => {
    let files = Utils.exec(`find ${dir} -type f | grep -E '.jpg$|.jpeg$|.png$|.gif$'`);
    return Widget.Window({
        name: 'wallpaper',
        class_name: "wallpapers",
        monitor,
        anchor: ["bottom", "top", "left"],
        exclusivity: "exclusive",
        layer: "overlay",
        margins: [12, 0, 12, 12],
        visible: false,
        child: Widget.Scrollable({
            vscroll: "never",
            hscroll: "always",
            child: Widget.Box({
                class_name: 'wallpaperContainer',
                vertical: false,
                children: files.bind().as(x => x.split("\n")
                    .filter(x => x !== "")
                    .map(path => ImagesList(path)))
            }),
        }),
    })
}

function ImagesList(path) {
    return Widget.Button({
        class_name: 'wallpaperButton',
        onPrimaryClick: () => {
            closeWindow();
            Utils.execAsync(['bash', '-c', `sh ${scriptDir} ${path}`]).catch(print);
        },
        child: Widget.Icon({
            class_name: 'wallpaperImage',
            size: 100,
            icon: `${path}`
        })
    })
}

export { Wallpaperpicker  }
//export { OpenWallpaper, Wallpaper }
