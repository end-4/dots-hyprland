const { Gtk } = imports.gi;

export function iconExists(iconName) {
    let iconTheme = Gtk.IconTheme.get_default();
    return iconTheme.has_icon(iconName);
}

export function substitute(str) {
    if(userOptions.icons.substitutions[str]) return userOptions.icons.substitutions[str];

    if (!iconExists(str)) str = str.toLowerCase().replace(/\s+/g, '-'); // Turn into kebab-case
    return str;
}