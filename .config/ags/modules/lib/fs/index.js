import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import App from 'resource:///com/github/Aylur/ags/app.js'
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'

/**
 * 
 * @param {String} file 
 * @param {String} data 
 * @param {|({encoding?: String|undefined})|null|undefined} options
 * @param {(err: any) => void} callback 
 */
export function writeFile (file, data, options, callback = () => {}) {
    Utils.writeFile (file, data).catch ((e) => {
        callback (e);
    });
}

/**
 * 
 * @param {String} file 
 * @param {'utf8'} encode 
 * @param {(err: any|undefined, content: String) => void} callback 
 */
export function readFile (file, encode = 'utf8', callback = () => {}) {
    Utils.readFileAsync (file).then ((content) => {
        callback (undefined, content);
    }).catch ((e) => {
        callback (e, '');
    });
}

/**
 * 
 * @param {String} file 
 * @param {(exists: boolean) => void} callback 
 */
export function exists (file, callback = () => {}) {
    (async () => {
        GLib.file_test (file, GLib.FileTest.EXISTS);
    }) ();
}

/**
 * 
 * @param {String} file1 
 * @param {String} file2 
 * @param {(err: Error|null) => void} callback 
 * @param {((progress: number) => void)|null} progress
 */
export function rename (file1, file2, callback, progress = null) {
    (async () => {
        const file = Gio.File.new_for_path (file1);
        callback (file.move (Gio.File.new_for_path (file2), Gio.FileCopyFlags.OVERWRITE, null, progress) ? null : new Error (`rename(): Failed to rename file ${file1} to ${file2}`));
    });
}

/**
 * 
 * @param {String} file 
 * @param {((err: Error|null) => void)|null} callback
 */
export function unlink (file, callback = null) {
    (async () => {
        const result = GLib.unlink (file);
        if (callback) { callback (result == 0 ? null : new Error (`Failed to unlink file ${file}`)); }
    });
}

/**
 * 
 * @param {String} file 
 * @param {String} data
 * @param {({encoding: String})|undefined|null} options 
 * @param {(err: Error|null, ) => void|null} callback 
 */
export function appendFile (file, data, options, callback) {
    const f = Gio.File.new_for_path (file);
    f.append_to_async (Gio.FileCreateFlags.PRIVATE, GLib.PRIORITY_DEFAULT, null, (source_object, res) => {
        const ostream = source_object.append_to (Gio.FileCreateFlags.PRIVATE, null);
        ostream.write (new TextEncoder ().encode (data), null);
    });
}

export default {
    rename,
    unlink,
    writeFile,
    readFile,
    exists
}