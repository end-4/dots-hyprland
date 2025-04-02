import App from 'resource:///com/github/Aylur/ags/app.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
import { parseJSONC } from '../.miscutils/jsonc.js';

function overrideConfigRecursive(userOverrides, configOptions = {}) {
    for (const [key, value] of Object.entries(userOverrides)) {
        if (typeof value === 'object' && !(value instanceof Array)) {
            overrideConfigRecursive(value, configOptions[key]);
        }
        else {
            configOptions[key] = value;
        }
    }
}

// Load default options from ~/.config/ags/modules/.configuration/default_options.jsonc
const configFileContents = Utils.readFile(`${App.configDir}/modules/.configuration/default_options.jsonc`);
let configOptions = parseJSONC(configFileContents);
const userOverrideContents = Utils.readFile(`${App.configDir}/user_options.jsonc`);
let userOverrides = parseJSONC(userOverrideContents);

// Override defaults with user's options
overrideConfigRecursive(userOverrides, configOptions);

globalThis['userOptions'] = configOptions;
export default configOptions;
