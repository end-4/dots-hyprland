const { Gio, GLib } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync, exec } = Utils;
import Todo from "../../services/todo.js";

export function hasUnterminatedBackslash(inputString) {
    // Use a regular expression to match a trailing odd number of backslashes
    const regex = /\\+$/;
    return regex.test(inputString);
}

export function launchCustomCommand(command) {
    const args = command.split(' ');
    if (args[0] == '>raw') { // Mouse raw input
        execAsync([`bash`, `-c`, `hyprctl keyword input:force_no_accel $(( 1 - $(hyprctl getoption input:force_no_accel -j | gojq ".int") ))`, `&`]).catch(print);
    }
    else if (args[0] == '>img') { // Change wallpaper
        execAsync([`bash`, `-c`, `${App.configDir}/scripts/color_generation/switchwall.sh`, `&`]).catch(print);
    }
    else if (args[0] == '>color') { // Generate colorscheme from color picker
        execAsync([`bash`, `-c`, `${App.configDir}/scripts/color_generation/switchcolor.sh`, `&`]).catch(print);
    }
    else if (args[0] == '>light') { // Light mode
        execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_cache_dir()}/ags/user && echo "-l" > ${GLib.get_user_cache_dir()}/ags/user/colormode.txt`])
            .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchwall.sh --noswitch`]))
            .catch(print);
    }
    else if (args[0] == '>dark') { // Dark mode
        execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_cache_dir()}/ags/user && echo "" > ${GLib.get_user_cache_dir()}/ags/user/colormode.txt`])
            .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchwall.sh --noswitch`]))
            .catch(print);
    }
    else if (args[0] == '>badapple') { // Black and white
        execAsync([`bash`, `-c`, `${App.configDir}/scripts/color_generation/applycolor.sh --bad-apple`]).catch(print)
    }
    else if (args[0] == '>material') { // Use material colors
        execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_cache_dir()}/ags/user && echo "material" > ${GLib.get_user_cache_dir()}/ags/user/colorbackend.txt`]).catch(print)
            .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchwall.sh --noswitch`]).catch(print))
            .catch(print);
    }
    else if (args[0] == '>pywal') { // Use Pywal (ik it looks shit but I'm not removing)
        execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_cache_dir()}/ags/user && echo "pywal" > ${GLib.get_user_cache_dir()}/ags/user/colorbackend.txt`]).catch(print)
            .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchwall.sh --noswitch`]).catch(print))
            .catch(print);
    }
    else if (args[0] == '>todo') { // Todo
        Todo.add(args.slice(1).join(' '));
    }
    else if (args[0] == '>shutdown') { // Shut down
        execAsync([`bash`, `-c`, `systemctl poweroff`]).catch(print);
    }
    else if (args[0] == '>reboot') { // Reboot
        execAsync([`bash`, `-c`, `systemctl reboot`]).catch(print);
    }
    else if (args[0] == '>sleep') { // Sleep
        execAsync([`bash`, `-c`, `systemctl suspend`]).catch(print);
    }
    else if (args[0] == '>logout') { // Log out
        execAsync([`bash`, `-c`, `pkill Hyprland || pkill sway`]).catch(print);
    }
}

export function execAndClose(command, terminal) {
    App.closeWindow('overview');
    if (terminal) {
        execAsync([`bash`, `-c`, `foot fish -C "${command}"`, `&`]).catch(print);
    }
    else
        execAsync(command).catch(print);
}

export function couldBeMath(str) {
    const regex = /^[0-9.+*/-]/;
    return regex.test(str);
}

export function expandTilde(path) {
    if (path.startsWith('~')) {
        return GLib.get_home_dir() + path.slice(1);
    } else {
        return path;
    }
}

function getFileIcon(fileInfo) {
    let icon = fileInfo.get_icon();
    if (icon) {
        // Get the icon's name
        return icon.get_names()[0];
    } else {
        // Default icon for files
        return 'text-x-generic';
    }
}

export function ls({ path = '~', silent = false }) {
    let contents = [];
    try {
        let expandedPath = expandTilde(path);
        if (expandedPath.endsWith('/'))
            expandedPath = expandedPath.slice(0, -1);
        let folder = Gio.File.new_for_path(expandedPath);

        let enumerator = folder.enumerate_children('standard::*', Gio.FileQueryInfoFlags.NONE, null);
        let fileInfo;
        while ((fileInfo = enumerator.next_file(null)) !== null) {
            let fileName = fileInfo.get_display_name();
            let fileType = fileInfo.get_file_type();

            let item = {
                parentPath: expandedPath,
                name: fileName,
                type: fileType === Gio.FileType.DIRECTORY ? 'folder' : 'file',
                icon: getFileIcon(fileInfo),
            };

            // Add file extension for files
            if (fileType === Gio.FileType.REGULAR) {
                let fileExtension = fileName.split('.').pop();
                item.type = `${fileExtension}`;
            }

            contents.push(item);
            contents.sort((a, b) => {
                const aIsFolder = a.type.startsWith('folder');
                const bIsFolder = b.type.startsWith('folder');
                if (aIsFolder && !bIsFolder) {
                    return -1;
                } else if (!aIsFolder && bIsFolder) {
                    return 1;
                } else {
                    return a.name.localeCompare(b.name); // Sort alphabetically within folders and files
                }
            });
        }
    } catch (e) {
        if (!silent) console.log(e);
    }
    return contents;
}