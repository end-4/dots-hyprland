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
    let files = Utils.exec(`bash -c "find $HOME/Pictures/wallpapers -type f | head -n 20 | grep -E '.jpg$|.jpeg$|.png$|.gif$'"`);
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
            hscroll: "alyways",
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
    return Widget.Button({
        class_name: 'wallpaperButton',
        onPrimaryClick: () => {
            App.closeWindow(`wallpaperpicker${id}`);
            Utils.execAsync(['bash', '-c', `sh ${scriptDir} ${path}`]).catch(print);
        },
        child: Widget.Icon({
            class_name: 'wallpaperImage',
            size: 180,
            icon: `${path}`
        })
    })
}
