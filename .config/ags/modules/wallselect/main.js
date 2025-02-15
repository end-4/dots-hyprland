import Widget from "resource:///com/github/Aylur/ags/widget.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
import App from "resource:///com/github/Aylur/ags/app.js";
import userOptions from "../.configuration/user_options.js";
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
const { Box, Label, EventBox, Scrollable, Button } = Widget;
// Constants
const CONFIG_DIR = GLib.get_home_dir() + '/.config/ags';
const WALLPAPER_DIR = GLib.get_home_dir() + (userOptions.wallselect.wallpaperFolder || '/Pictures/wallpapers');
const THUMBNAIL_DIR = GLib.build_filenamev([WALLPAPER_DIR, "thumbnails"]);

// Cached Variables
let wallpaperPathsPromise = null;
let cachedContent = null;
let fileMonitor = null;

// Initialize file monitoring
const initFileMonitor = () => {
    if (fileMonitor) return;

    const file = Gio.File.new_for_path(WALLPAPER_DIR);
    fileMonitor = file.monitor_directory(Gio.FileMonitorFlags.NONE, null);

    fileMonitor.connect('changed', (_, file, otherFile, eventType) => {
        const path = file.get_path();
        const ext = path.toLowerCase().split('.').pop();
        const validExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'tga', 'tiff', 'bmp', 'ico'];
        
        // Handle both file creation and deletion
        if ((eventType === Gio.FileMonitorEvent.CREATED || 
             eventType === Gio.FileMonitorEvent.DELETED) && 
            validExts.includes(ext)) {
            
            const action = eventType === Gio.FileMonitorEvent.CREATED ? 'added' : 'deleted';
            
            if (eventType === Gio.FileMonitorEvent.DELETED) {
                // Get the thumbnail path
                const filename = path.split('/').pop();
                const thumbnailPath = GLib.build_filenamev([THUMBNAIL_DIR, filename]);
                
                // Delete the thumbnail if it exists
                if (GLib.file_test(thumbnailPath, GLib.FileTest.EXISTS)) {
                    GLib.unlink(thumbnailPath);
                }
            }
            
            // Regenerate thumbnails
            Utils.execAsync([`bash`, `${CONFIG_DIR}/scripts/generate_thumbnails.sh`])
                .then(() => {
                    // Reset caches
                    wallpaperPathsPromise = null;
                    cachedContent = null;
                    
                    // Refresh UI if visible
                    if (App.getWindow('wallselect')?.visible) {
                        App.closeWindow('wallselect');
                        App.openWindow('wallselect');
                    }
                });
        }
    });
};


// Wallpaper Button
const WallpaperButton = (path) => 
    Widget.Button({
        child: Box({ className: "preview-box", css: `background-image: url("${path}");` }),
        onClicked: () => {
                Utils.execAsync(['sh', `${CONFIG_DIR}/scripts/color_generation/switchwall.sh`, path.replace("thumbnails", "")]);
                App.closeWindow("wallselect");
        },
    });

// Get Wallpaper Paths
const getWallpaperPaths = () => {
    if (wallpaperPathsPromise) return wallpaperPathsPromise;
    wallpaperPathsPromise = Utils.execAsync(
        `find ${GLib.shell_quote(THUMBNAIL_DIR)} -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.tga" -o -iname "*.tiff" -o -iname "*.bmp" -o -iname "*.ico" \\)`
    ).then(files => files.split("\n").filter(Boolean));
    return wallpaperPathsPromise;
};

// Create Content
const createContent = async () => {
    if (cachedContent) return cachedContent;

    try {
        const wallpaperPaths = await getWallpaperPaths();

        if (wallpaperPaths.length === 0) {
            return createPlaceholder();
        }

        cachedContent = EventBox({
            onPrimaryClick: () => App.closeWindow("wallselect"),
            onSecondaryClick: () => App.closeWindow("wallselect"),
            onMiddleClick: () => App.closeWindow("wallselect"),
            child: Scrollable({
                hexpand: true,
                vexpand: false,
                hscroll: "always",
                vscroll: "never",
                child: Box({
                    className: "wallpaper-list",
                    children: wallpaperPaths.map(WallpaperButton),
                }),
            }),
        });

        return cachedContent;

    } catch (error) {
        return Box({
            className: "wallpaper-error",
            vexpand: true,
            hexpand: true,
            children: [
                Label({ label: "Error loading wallpapers.", className: "txt-large txt-error", }),
            ],
        });
    }
};

// Placeholder content when no wallpapers found
const createPlaceholder = () => Box({
    className: 'wallpaper-placeholder',
    vertical: true,
    vexpand: true,
    hexpand: true,
    spacing: 10,
    children: [
        Box({
            vertical: true,
            vpack: 'center',
            hpack: 'center',
            vexpand: true,
            children: [
                Label({ label: 'No wallpapers found.', className: 'txt-norm onSurfaceVariant', }),
                Label({ label: 'Generate thumbnails to get started.',opacity:0.8, className: 'txt-small onSurfaceVariant', }),
            ],
        }),
    ],
});

// Generate Thumbnails Button
const GenerateButton = () => Widget.Button({
    className: 'button-accent generate-thumbnails',
    child: Box({
        spacing:8,
        children: [
            Widget.Icon({ icon: 'view-refresh-symbolic', size: 16, }),
            Widget.Label({ className:"txt-small onSurfaceVariant",label: 'Generate Thumbnails', }),
        ],
    }),
    tooltipText: 'Regenerate all wallpaper thumbnails',
    onClicked: () => {
        Utils.execAsync([`bash`, `${CONFIG_DIR}/scripts/generate_thumbnails.sh`])
            .then(() => {
                cachedContent = null; // Invalidate cache
                App.closeWindow('wallselect');
                App.openWindow('wallselect');
            });
    },
});

// Toggle Wallselect Window
const toggleWindow = () => {
    const win = App.getWindow('wallselect');
    if (!win) return;
    win.visible = !win.visible;
};
export { toggleWindow };

// Initialize monitoring when the module loads
initFileMonitor();

// Main Window
export default () => Widget.Window({
    name: "wallselect",
    anchor: ['top', 'bottom', 'right', 'left'],
    layer: 'overlay',
    visible: false,
    child: Widget.Overlay({
        child: EventBox({
            onPrimaryClick: () => App.closeWindow("wallselect"),
            onSecondaryClick: () => App.closeWindow("wallselect"),
            onMiddleClick: () => App.closeWindow("wallselect"),
            child: Box({ css: 'min-height: 1000px;', }),
        }),
        overlays: [
            Box({
                vertical: true,
                className: "sidebar-right spacing-v-15",
                vpack: 'start',
                children: [
                    Box({
                        className: "wallselect-header",
                        children: [
                            Box({ hexpand: true }),
                            GenerateButton(),
                        ],
                    }),
                    Box({
                        vertical: true,
                        className: "sidebar-module",
                        setup: (self) =>
                            self.hook(
                                App,
                                async (_, name, visible) => {
                                    if (name === "wallselect" && visible) {
                                        const content = await createContent();
                                        self.children = [content];
                                    }
                                },
                                "window-toggled",
                            ),
                    }),
                ],
            }),
        ],
    }),
});