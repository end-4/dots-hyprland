export function getNestedProperty(obj: any, path: string) {
    return path.split('.').reduce((current: { [x: string]: any; hasOwnProperty: (arg0: any) => any; }, key: string | number) => {
        return (current && typeof current === 'object' && current.hasOwnProperty(key)) ? current[key] : undefined;
    }, obj);
}

export function updateNestedProperty(obj: any, path: string, newValue: any) {
    const pathArray = path.split('.');
    const lastKeyIndex = pathArray.length - 1;

    let current = obj;

    for (let i = 0; i < lastKeyIndex; i++) {
        const key = pathArray[i];
        if (!current || typeof current !== 'object') {
            return false; // Previous part of path is not an object
        }

        if (!current.hasOwnProperty(key)) {
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
