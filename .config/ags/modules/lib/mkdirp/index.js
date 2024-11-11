import Glib from 'gi://GLib';

/**
 * 
 * @param {String} path 
 * @param {Number} mode
 */
async function mkdirp (path, mode = 755) {
    /**
     * 
     * @param {String} path
     * @param {Number} mode 
     */
    this.sync = (path, mode = 755) => {
        return Glib.mkdir_with_parents (path, mode) == 0;
    } 

    return this.sync (path, mode);
}

export default mkdirp;