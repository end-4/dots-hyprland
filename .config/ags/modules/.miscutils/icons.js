const { Gtk, Gio } = imports.gi;

import { fileExists } from "./files.js";
import Applications from 'resource:///com/github/Aylur/ags/service/applications.js';

export function iconExists(iconName) {
    let iconTheme = Gtk.IconTheme.get_default();
    return iconTheme.has_icon(iconName);
}

export function substitute(str) {
    if(userOptions.icons.substitutions[str]) return userOptions.icons.substitutions[str];

    if (!iconExists(str)) str = str.toLowerCase().replace(/\s+/g, '-'); // Turn into kebab-case
    return str;
}

export const levenshteinDistance = (a, b) => {
    if (!a.length) { return b.length }
    if (!b.length) { return a.length }

    let f = Array.from(new Array(a.length + 1),
        () => new Array(b.length + 1).fill(0))

    for (let i = 0; i <= b.length; i++) { f[0][i] = i; }
    for (let i = 0; i <= a.length; i++) { f[i][0] = i; }

    for (let i = 1; i <= a.length; i++) {
        for (let j = 1; j <= b.length; j++) {
            if (a.charAt(i - 1) === b.charAt(j - 1)) {
                f[i][j] = f[i-1][j-1]
            } else {
                f[i][j] = Math.min(f[i-1][j-1], Math.min(f[i][j-1], f[i-1][j])) + 1
            }
        }
    }

    return f[a.length][b.length]
}

export const getAllFiles = (dir, files = []) => {
    if (!fileExists(dir)) { return [] }
    const file = Gio.File.new_for_path(dir);
    const enumerator = file.enumerate_children('standard::name,standard::type',
        Gio.FileQueryInfoFlags.NONE, null);

    for (const info of enumerator) {
        if (info.get_file_type() === Gio.FileType.DIRECTORY) {
            files.push(getAllFiles(`${dir}/${info.get_name()}`))
        } else {
            files.push(`${dir}/${info.get_name()}`)
        }
    }

    return files.flat(1);
}

export const searchIcons = (appClass) => {
    const appClassLower = appClass.toLowerCase()
    let path = searchIconsByAppName(appClassLower)
    if (path === "") {
        if (cachePath[appClassLower]) { path = cachePath[appClassLower] }
        else {
            path = searchIconsInPath(appClass.toLowerCase(), icon_files)
            cachePath[appClassLower] = path
        }
    }
    if (path === "") { path = substitute(appClass) }
    return path
}

export const searchIconsInPath = (appClass, files) => {
    appClass = appClass.toLowerCase()

    if (!files.length) { return "" }

    let appro = 0x3f3f3f3f
    let path = ""

    for (const item of files) {
        let score = levenshteinDistance(item.split("/").pop().toLowerCase().split(".")[0], appClass)

        if (score < appro) {
            appro = score
            path = item
        }
    }

    return path
}

export const searchIconsByAppName = (appName) => {
    let app = Applications.query(appName)?.[0]
    return app ? app.icon_name : ''
}

export const icon_files = userOptions.icons.searchPaths.map(e => getAllFiles(e)).flat(1)
export let cachePath = new Map()