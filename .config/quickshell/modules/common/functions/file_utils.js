/**
 * Trims the File protocol off the input string
 * @param {string} str
 * @returns {string}
 */
function trimFileProtocol(str) {
    return str.startsWith("file://") ? str.slice(7) : str;
}

