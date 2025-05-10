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

function applyToQtObject(qtObj, jsonObj) {
    if (!qtObj || typeof jsonObj !== "object" || jsonObj === null) return;

    for (let key in jsonObj) {
        if (!qtObj.hasOwnProperty(key)) continue;

        // Check if the property is a QtObject (not a value)
        const value = qtObj[key];
        const jsonValue = jsonObj[key];

        // If it's an object and not an array, recurse
        if (value && typeof value === "object" && !Array.isArray(value)) {
            applyToQtObject(value, jsonValue);
        } else {
            // Otherwise, assign the value
            qtObj[key] = jsonValue;
        }
    }
}
