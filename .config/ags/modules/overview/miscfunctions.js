const { Gio, GLib } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync, exec } = Utils;
import Todo from "../../services/todo.js";
import { darkMode } from '../.miscutils/system.js';

export function hasUnterminatedBackslash(inputString) {
    // Use a regular expression to match a trailing odd number of backslashes
    const regex = /\\+$/;
    return regex.test(inputString);
}

export function launchCustomCommand(command) {
    const args = command.toLowerCase().split(' ');
    if (args[0] == '>raw') { // Mouse raw input
        Utils.execAsync('hyprctl -j getoption input:accel_profile')
            .then((output) => {
                const value = JSON.parse(output)["str"].trim();
                if (value != "[[EMPTY]]" && value != "") {
                    execAsync(['bash', '-c', `hyprctl keyword input:accel_profile '[[EMPTY]]'`]).catch(print);
                }
                else {
                    execAsync(['bash', '-c', `hyprctl keyword input:accel_profile flat`]).catch(print);
                }
            })
    }
    else if (args[0] == '>img') { // Change wallpaper
        execAsync([`bash`, `-c`, `${App.configDir}/scripts/color_generation/switchwall.sh`, `&`]).catch(print);
    }
    else if (args[0] == '>color') { // Generate colorscheme from color picker
        if (!args[1])
            execAsync([`bash`, `-c`, `${App.configDir}/scripts/color_generation/switchcolor.sh --pick`, `&`]).catch(print);
        else if(args[1][0] === '#')
            execAsync([`bash`, `-c`, `${App.configDir}/scripts/color_generation/switchcolor.sh "${args[1]}"`, `&`]).catch(print);
    }
    else if (args[0] == '>light') { // Light mode
        darkMode.value = false;
        execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_state_dir()}/ags/user && sed -i "1s/.*/light/"  ${GLib.get_user_state_dir()}/ags/user/colormode.txt`])
            .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchcolor.sh`]))
            .catch(print);
    }
    else if (args[0] == '>dark') { // Dark mode
        darkMode.value = true;
        execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_state_dir()}/ags/user && sed -i "1s/.*/dark/"  ${GLib.get_user_state_dir()}/ags/user/colormode.txt`])
            .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchcolor.sh`]))
            .catch(print);
    }
    else if (args[0] == '>badapple') { // Black and white
        execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_state_dir()}/ags/user && sed -i "3s/.*/monochrome/" ${GLib.get_user_state_dir()}/ags/user/colormode.txt`])
            .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchcolor.sh`]))
            .catch(print);
    }
    else if (args[0] == '>material') { // Use material colors
        execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_state_dir()}/ags/user && echo "material" > ${GLib.get_user_state_dir()}/ags/user/colorbackend.txt`]).catch(print)
            .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchwall.sh --noswitch`]).catch(print))
            .catch(print);
    }
    else if (args[0] == '>pywal') { // Use Pywal (ik it looks shit but I'm not removing)
        execAsync([`bash`, `-c`, `mkdir -p ${GLib.get_user_state_dir()}/ags/user && echo "pywal" > ${GLib.get_user_state_dir()}/ags/user/colorbackend.txt`]).catch(print)
            .then(execAsync(['bash', '-c', `${App.configDir}/scripts/color_generation/switchwall.sh --noswitch`]).catch(print))
            .catch(print);
    }
    else if (args[0] == '>todo') { // Todo
        Todo.add(args.slice(1).join(' '));
    }
    else if (args[0] == '>shutdown') { // Shut down
        execAsync([`bash`, `-c`, `systemctl poweroff || loginctl poweroff`]).catch(print);
    }
    else if (args[0] == '>reboot') { // Reboot
        execAsync([`bash`, `-c`, `systemctl reboot || loginctl reboot`]).catch(print);
    }
    else if (args[0] == '>sleep') { // Sleep
        execAsync([`bash`, `-c`, `systemctl suspend || loginctl suspend`]).catch(print);
    }
    else if (args[0] == '>logout') { // Log out
        execAsync([`bash`, `-c`, `pkill Hyprland || pkill sway`]).catch(print);
    }
}

export function execAndClose(command, terminal) {
    App.closeWindow('overview');
    if (terminal) {
        execAsync([`bash`, `-c`, `${userOptions.apps.terminal} fish -C "${command}"`, `&`]).catch(print);
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
