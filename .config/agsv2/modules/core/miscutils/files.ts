import { Gio, GLib } from "astal";

export function fileExists(filePath: string): boolean {
    let file = Gio.File.new_for_path(filePath);
    return file.query_exists(null);
}

export function expandTilde(path: string): string {
    if (path.startsWith('~')) {
        return GLib.get_home_dir() + path.slice(1);
    } else {
        return path;
    }
}