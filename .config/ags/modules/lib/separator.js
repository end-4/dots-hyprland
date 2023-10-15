const { Gdk, Gtk } = imports.gi;
import { App, Service, Utils, Widget } from '../../imports.js';
const { execAsync, exec } = Utils;
import { setupCursorHover, setupCursorHoverAim } from "./cursorhover.js";
import { MaterialIcon } from './materialicon.js';

export const separatorLine = Widget.Box({
    className: 'separator-line',
})