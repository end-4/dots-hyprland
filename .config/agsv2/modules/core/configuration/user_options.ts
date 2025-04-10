import { readFile } from 'astal/file';
import { parseJSONC } from '../miscutils/jsonc';
import { GLib } from 'astal';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function overrideConfigRecursive(userOverrides: any, configOptions: any = {}) {
    for (const [key, value] of Object.entries(userOverrides)) {
        if (typeof value === 'object' && !(value instanceof Array) && configOptions[key]) {
            overrideConfigRecursive(value, configOptions[key]);
        } else {
            configOptions[key] = value;
        }
    }
}

// Load default options from ~/.config/agsv2/modules/core/configuration/default_options.jsonc
const defaultConfigFile = `${GLib.get_user_config_dir()}/agsv2/modules/core/configuration/default_options.jsonc`;
const defaultConfigFileContents = readFile(defaultConfigFile);
export const userOptionsDefaults = parseJSONC(defaultConfigFileContents);

// Clone the default config to avoid modifying the original
export const userOptions = JSON.parse(JSON.stringify(userOptionsDefaults));

// Load user overrides
const userOverrideFile = `${GLib.get_user_config_dir()}/agsv2/user_options.jsonc`;
const userOverrideContents = readFile(userOverrideFile);
const userOverrides = parseJSONC(userOverrideContents);

// Override defaults with user's options
overrideConfigRecursive(userOverrides, userOptions);
