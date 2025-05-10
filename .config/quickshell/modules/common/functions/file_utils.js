function trimFileProtocol(str) {
    return str.startsWith("file://") ? str.slice(7) : str;
}

