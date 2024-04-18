const { Gio, GLib } = imports.gi

const exists = (path) => Gio.File.new_for_path(path).query_exists(null);

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
    if (!exists(dir)) { return [] }
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

export const searchIcons = (appClass, files) => {
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