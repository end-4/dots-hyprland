const { GLib } = imports.gi;
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync, exec } = Utils;

import { getNestedProperty, updateNestedProperty } from "../.miscutils/objects.js";
import { ConfigSpinButton, ConfigToggle } from "./configwidgets.js";

const AGS_CONFIG_FILE = `${App.configDir}/user_options.jsonc`;
const HYPRLAND_CONFIG_FILE = `${GLib.get_user_config_dir()}/hypr/custom/general.conf`;

export const AgsToggle = ({
    icon, name, desc = null,
    option, resetButton = true, save = true,
    extraOnChange = () => { }, extraOnReset = () => { },
    ...rest
}) => ConfigToggle({
    icon: icon,
    name: name,
    desc: `${desc}\n\n${option}\nEdit in ${AGS_CONFIG_FILE}`,
    resetButton: resetButton,
    initValue: getNestedProperty(userOptions, option),
    fetchValue: () => getNestedProperty(userOptions, option),
    onChange: (self, newValue) => {
        updateNestedProperty(userOptions, option, newValue);
        if (save) execAsync(['bash', '-c', `${App.configDir}/scripts/ags/agsconfigurator.py \
            --key ${option} \
            --value ${newValue} \
            --file ${AGS_CONFIG_FILE}`
        ]).catch(print);
        extraOnChange(self, newValue);
    },
    onReset: async (self) => {
        updateNestedProperty(userOptions, option,
            getNestedProperty(userOptionsDefaults, option));
        if (save) exec(`bash -c '${App.configDir}/scripts/ags/agsconfigurator.py \
            --key ${option} \
            --reset \
            --file ${AGS_CONFIG_FILE}'`);
        extraOnReset(self);
    },
    ...rest
});

export const AgsSpinButton = ({
    icon, name, desc = null,
    option, resetButton = true,
    save = true, extraOnChange = () => { }, extraOnReset = () => { },
    ...rest
}) => ConfigSpinButton({
    icon: icon,
    name: name,
    desc: `${desc}\n\n${option}\nEdit in ${AGS_CONFIG_FILE}`,
    resetButton: resetButton,
    initValue: getNestedProperty(userOptions, option),
    fetchValue: () => getNestedProperty(userOptions, option),
    step: 10, minValue: 0, maxValue: 1000,
    onChange: (self, newValue) => {
        updateNestedProperty(userOptions, option, newValue);
        if (save) execAsync(['bash', '-c', `${App.configDir}/scripts/ags/agsconfigurator.py \
            --key ${option} \
            --value ${newValue} \
            --file ${AGS_CONFIG_FILE}`
        ]).catch(print);
        extraOnChange(self, newValue);
    },
    onReset: async () => {
        updateNestedProperty(userOptions, option,
            getNestedProperty(userOptionsDefaults, option));
        if (save) exec(`bash -c '${App.configDir}/scripts/ags/agsconfigurator.py \
            --key ${option} \
            --reset \
            --file ${AGS_CONFIG_FILE}'`);
        extraOnReset(self);
    },
    ...rest,
});

export const HyprlandToggle = ({
    icon, name, desc = null,
    option, resetButton = true,
    enableValue = 1, disableValue = 0,
    extraOnChange = () => { }, extraOnReset = () => { }, save = true
}) => ConfigToggle({
    icon: icon,
    name: name,
    desc: `${desc}\n\n${option}\nEdit in ${HYPRLAND_CONFIG_FILE}`,
    resetButton: resetButton,
    initValue: JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"] != 0,
    fetchValue: () => JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"] != 0,
    onChange: (self, newValue) => {
        if (save)
            execAsync(['bash', '-c', `${App.configDir}/scripts/hyprland/hyprconfigurator.py \
            --key ${option} \
            --value ${newValue ? enableValue : disableValue} \
            --file ${HYPRLAND_CONFIG_FILE}`
            ]).catch(print);

        else
            execAsync(['hyprctl', 'keyword', option, `${newValue ? enableValue : disableValue}`]).catch(print);

        extraOnChange(self, newValue);
    },
    onReset: async (self) => {
        if (save)
            exec(`bash -c '${App.configDir}/scripts/hyprland/hyprconfigurator.py \
                --key ${option} \
                --reset \
                --file "${HYPRLAND_CONFIG_FILE}"'`);

        else
            exec('hyprctl reload');
        extraOnReset(self);
    },
});

export const HyprlandSpinButton = ({
    icon, name, desc = null,
    option, resetButton = true, save = true,
    extraOnChange = () => { }, extraOnReset = () => { },
    ...rest
}) => ConfigSpinButton({
    icon: icon,
    name: name,
    desc: `${desc}\n\n${option}\nEdit in ${HYPRLAND_CONFIG_FILE}`,
    resetButton: resetButton,
    initValue: Number(JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"]),
    fetchValue: () => Number(JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"]),
    onChange: (self, newValue) => {
        if (save)
            execAsync(['bash', '-c', `${App.configDir}/scripts/hyprland/hyprconfigurator.py \
                --key ${option} \
                --value ${newValue} \
                --file ${HYPRLAND_CONFIG_FILE}`
            ]).catch(print);

        else
            execAsync(['hyprctl', 'keyword', option, `${newValue}`]).catch(print);

        extraOnChange(self, newValue);
    },
    onReset: async (self) => {
        if (save)
            exec(`bash -c '${App.configDir}/scripts/hyprland/hyprconfigurator.py \
                --key ${option} \
                --reset \
                --file "${HYPRLAND_CONFIG_FILE}"'`);

        else
            exec('hyprctl reload');
        extraOnReset(self);
    },
    ...rest,
});

