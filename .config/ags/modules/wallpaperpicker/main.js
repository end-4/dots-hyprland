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

function setWallpaper(path) {
    Utils.execAsync(['bash', '-c', `sh ${scriptDir} ${path}`]).catch(print);
}

function closeWindow() {
    App.closeWindow('wallpaperpicker')
}

export const Wallpaperpicker = (monitor = 0) => {
    let files = Utils.exec(`bash -c "find $HOME/Pictures/wallpapers -type f | head -n 20 | grep -E '.jpg$|.jpeg$|.png$|.gif$'"`);
    return Widget.Window({
        name: 'wallpaperpicker',
        class_name: "wallpapers",
        monitor,
        anchor: ["top", "left", "right"],
        exclusivity: "normal",
        layer: "overlay",
        margins: [7],
        visible: false,
        child: Widget.Scrollable({
            vscroll: "never",
            hscroll: "alyways",
            class_name: 'wallpaperScroll',
            child: Widget.Box({
                class_name: 'wallpaperContainer',
                children: files.split("\n").filter(x => x !== "")
                    .map(path => ImagesList(path))
            }),
        }),
        setup: (self) => {
            self.keybind("Escape", () => closeWindow());
        },
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
            size: 180,
            icon: `${path}`
        })
    })
}
