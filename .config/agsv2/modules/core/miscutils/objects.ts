// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function getNestedProperty(obj: any, path: string) {
    return path.split('.').reduce((current, key: string) => {
        return current && typeof current === 'object' && Object.prototype.hasOwnProperty.call(current, key)
            ? current[key]
            : undefined;
    }, obj);
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function updateNestedProperty(obj: any, path: string, newValue: any) {
    const pathArray = path.split('.');
    const lastKeyIndex = pathArray.length - 1;

    let current = obj;

    for (let i = 0; i < lastKeyIndex; i++) {
        const key = pathArray[i];
        if (!current || typeof current !== 'object') {
            return false; // Previous part of path is not an object
        }

        if (!Object.prototype.hasOwnProperty.call(current, key)) {
            current[key] = {}; // Create the missing object
        }
        current = current[key];
    }

    const lastKey = pathArray[lastKeyIndex];

    if (!current || typeof current !== 'object') {
        return false; // Parent is not an object
    }

    current[lastKey] = newValue;
    return true;
}
