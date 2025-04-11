import App from 'resource:///com/github/Aylur/ags/app.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
import { parseJSONC } from '../.miscutils/jsonc.js';

function overrideConfigRecursive(userOverrides, configOptions = {}) {
    for (const [key, value] of Object.entries(userOverrides)) {
        if (typeof value === 'object'
            && !(value instanceof Array)
            && configOptions[key]) {
            overrideConfigRecursive(value, configOptions[key]);
        }
        else {
            configOptions[key] = value;
        }
    }
}

// Load default options from ~/.config/ags/modules/.configuration/default_options.jsonc
const defaultConfigFile = `${App.configDir}/modules/.configuration/default_options.jsonc`;
const defaultConfigFileContents = Utils.readFile(defaultConfigFile);
const defaultConfigOptions = parseJSONC(defaultConfigFileContents);

// Clone the default config to avoid modifying the original
let configOptions = JSON.parse(JSON.stringify(defaultConfigOptions));

// Load user overrides
const userOverrideFile = `${App.configDir}/user_options.jsonc`;
const userOverrideContents = Utils.readFile(userOverrideFile);
const userOverrides = parseJSONC(userOverrideContents);

// Override defaults with user's options
overrideConfigRecursive(userOverrides, configOptions);

globalThis['userOptionsDefaults'] = defaultConfigOptions;
globalThis['userOptions'] = configOptions;
export default configOptions;
