const { Gio, GLib } = imports.gi;
import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { exec, execAsync } = Utils;

class TodoService extends Service {
    static {
        Service.register(
            this,
            { 'updated': [], },
        );
    }

    _todoPath = '';
    _todoJson = [];

    refresh(value) {
        this.emit('updated', value);
    }

    connectWidget(widget, callback) {
        this.connect(widget, callback, 'updated');
    }

    get todo_json() {
        return this._todoJson;
    }

    _save() {
        Utils.writeFile(JSON.stringify(this._todoJson), this._todoPath)
            .catch(print);
    }

    add(content) {
        this._todoJson.push({ content, done: false });
        this._save();
        this.emit('updated');
    }

    check(index) {
        this._todoJson[index].done = true;
        this._save();
        this.emit('updated');
    }

    uncheck(index) {
        this._todoJson[index].done = false;
        this._save();
        this.emit('updated');
    }

    remove(index) {
        this._todoJson.splice(index, 1);
        Utils.writeFile(JSON.stringify(this._todoJson), this._todoPath)
            .catch(print);
        this.emit('updated');
    }

    constructor() {
        super();
        this._todoPath = `${GLib.get_user_cache_dir()}/ags/user/todo.json`;
        try {
            const fileContents = Utils.readFile(this._todoPath);
            this._todoJson = JSON.parse(fileContents);
        }
        catch {
            Utils.exec(`bash -c 'mkdir -p ${GLib.get_user_cache_dir()}/ags/user'`);
            Utils.exec(`touch ${this._todoPath}`);
            Utils.writeFile("[]", this._todoPath).then(() => {
                this._todoJson = JSON.parse(Utils.readFile(this._todoPath))
            }).catch(print);
        }
    }
}

// the singleton instance
const service = new TodoService();

// make it global for easy use with cli
globalThis.todo = service;

// export to use in other modules
export default service;