const { Gio, GLib } = imports.gi;
import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { exec, execAsync } = Utils;

const clamp = (num, min, max) => Math.min(Math.max(num, min), max);
function fileExists(filePath) {
    let file = Gio.File.new_for_path(filePath);
    return file.query_exists(null);
}

class WallpaperService extends Service {
    static {
        Service.register(
            this,
            { 'updated': [], },
        );
    }

    _wallPath = '';
    _wallJson = [];

    _save() {
        Utils.writeFile(JSON.stringify(this._wallJson), this._wallPath)
            .catch(print);
    }

    add(path) {
        this._wallJson.push(path);
        this._save();
        this.emit('updated');
    }

    set(path, monitor = -1) {
        if(this._wallJson.length == 0) this._wallJson.push("");
        if (monitor == -1)
            this._wallJson.fill(path);
        else
            this._wallJson[monitor] = path;

        this._save();
        this.emit('updated');
    }

    get(monitor = 0) {
        return this._wallJson[monitor];
    }

    constructor() {
        super();
        this._wallPath = `${GLib.get_user_cache_dir()}/ags/user/wallpaper.json`;
        if (!fileExists(this._wallPath)) { // No? create file with empty array
            Utils.exec(`bash -c 'mkdir -p ${GLib.get_user_cache_dir()}/ags/user'`);
            Utils.exec(`touch ${this._wallPath}`);
            Utils.writeFile('[]', this._wallPath).then(() => {
                this._wallJson = JSON.parse(Utils.readFile(this._wallPath))
            }).catch(print);
        }
        else {
            const fileContents = Utils.readFile(this._wallPath);
            this._wallJson = JSON.parse(fileContents);
        }
    }
}

// instance
const service = new WallpaperService();
// make it global for easy use with cli
globalThis['wallpaper'] = service;
export default service;