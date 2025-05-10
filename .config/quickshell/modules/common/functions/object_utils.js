function trimFileProtocol(str) {
    return str.startsWith("file://") ? str.slice(7) : str;
}

function toPlainObject(qtObj) {
    if (qtObj === null || typeof qtObj !== "object") return qtObj;

    // Handle arrays
    if (Array.isArray(qtObj)) {
        return qtObj.map(toPlainObject);
    }

    const result = ({});
    for (let key in qtObj) {
        if (
            typeof qtObj[key] !== "function" &&
            !key.startsWith("objectName") &&
            !key.startsWith("children") &&
            !key.startsWith("object") &&
            !key.startsWith("parent") &&
            !key.startsWith("metaObject") &&
            !key.startsWith("destroyed") &&
            !key.startsWith("reloadableId")
        ) {
            result[key] = toPlainObject(qtObj[key]);
        }
    }
    return result;
}