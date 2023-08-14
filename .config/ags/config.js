// Import
const { exec, execAsync, CONFIG_DIR } = ags.Utils;
Object.keys(imports['modules']).forEach(m => imports['modules'][m]);
Object.keys(imports['windows']).forEach(m => imports['windows'][m]);

// Config object
var config = {
    style: CONFIG_DIR + '/style.css',
    stackTraceOnError: true,
    windows: [
        imports.windows.bar.bar,
        imports.windows.corners.corner_topleft,
        imports.windows.corners.corner_topright,
        imports.windows.corners.corner_bottomleft,
        imports.windows.corners.corner_bottomright,
        imports.windows.osd.indicator(0),
    ],
};

exec('sassc ' + CONFIG_DIR + '/scss/main.scss ' + CONFIG_DIR + '/style.css');
ags.App.resetCss();
ags.App.applyCss(`${CONFIG_DIR}/style.css`);
