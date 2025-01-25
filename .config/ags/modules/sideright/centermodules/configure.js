const { GLib } = imports.gi;
import Hyprland from "resource:///com/github/Aylur/ags/service/hyprland.js";
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
const { Box, Button, Icon, Label, Scrollable, Slider, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from "../../.commonwidgets/materialicon.js";
import { setupCursorHover } from "../../.widgetutils/cursorhover.js";
import {
  ConfigGap,
  ConfigSpinButton,
  ConfigToggle,
} from "../../.commonwidgets/configwidgets.js";

// Hyprland config file path
const configFile = GLib.get_home_dir() + "/.config/hypr/hyprland/HyprAGS.conf";

// Ensure the config file exists
function ensureConfigFileExists() {
  if (!GLib.file_test(configFile, GLib.FileTest.EXISTS)) {
    execAsync(["touch", configFile]).catch((err) =>
      logError("Error creating config file", err),
    );
  }
}

// Helper to update the config file
function updateConfig(option, value) {
  execAsync([
    "bash",
    "-c",
    `
        if grep -q "^${option} =" ${configFile}; then
            sed -i "s/^${option} = .*/${option} = ${value}/" ${configFile}
        else
            echo "${option} = ${value}" >> ${configFile}
        fi
        `,
  ]).catch((err) => logError("Failed to update config", err));
}

// Toggles for Hyprland settings
const HyprlandToggle = ({
  icon,
  name,
  desc = null,
  option,
  enableValue = 1,
  disableValue = 0,
  extraOnChange = () => {},
}) =>
  ConfigToggle({
    icon: icon,
    name: name,
    desc: desc,
    initValue: JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"] != 0,
    onChange: (self, newValue) => {
      execAsync([
        "hyprctl",
        "keyword",
        option,
        `${newValue ? enableValue : disableValue}`,
      ])
        .then(() => {
          updateConfig(option, newValue ? enableValue : disableValue);
          extraOnChange(self, newValue);
        })
        .catch((err) => logError("Error applying change", err));
    },
  });

// SpinButton for numeric settings
const HyprlandSpinButton = ({ icon, name, desc = null, option, ...rest }) =>
  ConfigSpinButton({
    icon: icon,
    name: name,
    desc: desc,
    initValue: Number(
      JSON.parse(exec(`hyprctl getoption -j ${option}`))["int"],
    ),
    onChange: (self, newValue) => {
      execAsync(["hyprctl", "keyword", option, `${newValue}`])
        .then(() => {
          updateConfig(option, newValue);
        })
        .catch((err) => logError("Error applying change", err));
    },
    ...rest,
  });

const Subcategory = (children) =>
  Box({
    className: "margin-left-20",
    vertical: true,
    children: children,
  });

export default (props) => {
  const ConfigSection = ({ name, children }) =>
    Box({
      vertical: true,
      className: "spacing-v-5",
      children: [
        Label({
          hpack: "center",
          className: "txt txt-large margin-left-10",
          label: name,
        }),
        Box({
          className: "margin-left-10 margin-right-10",
          vertical: true,
          children: children,
        }),
      ],
    });

  const mainContent = Scrollable({
    vexpand: true,
    child: Box({
      vertical: true,
      className: "spacing-v-10",
      children: [
        // Roundings Section
        ConfigSection({
          name: getString("Window"),
          children: [
            HyprlandSpinButton({
              icon: "crop_square",
              name: getString("Window Roundings"),
              desc: getString(
                "[Hyprland]\nAdjust the window corner roundings.",
              ),
              option: "decoration:rounding",
              minValue: 0,
              maxValue: 50,
              step: 1,
              onChange: (self, newValue) => {
                updateConfig("decoration:rounding", newValue);
              },
            }),
          ],
        }),
        // Effects Section
        ConfigSection({
          name: getString("Effects"),
          children: [
            ConfigToggle({
              icon: "border_clear",
              name: getString("Transparency"),
              desc: getString(
                "[AGS]\nMake shell elements transparent\nBlur is also recommended if you enable this",
              ),
              initValue:
                exec(
                  `bash -c "sed -n '2p' ${GLib.get_user_state_dir()}/ags/user/colormode.txt"`,
                ) == "transparent",
              onChange: (self, newValue) => {
                const transparency = newValue == 0 ? "opaque" : "transparent";
                execAsync([
                  `bash`,
                  `-c`,
                  `mkdir -p ${GLib.get_user_state_dir()}/ags/user && sed -i "2s/.*/${transparency}/"  ${GLib.get_user_state_dir()}/ags/user/colormode.txt`,
                ])
                  .then(
                    execAsync([
                      "bash",
                      "-c",
                      `${App.configDir}/scripts/color_generation/switchcolor.sh`,
                    ]),
                  )
                  .then(() => {
                    if (newValue) {
                      updateConfig("decoration:active_opacity", 0.85);
                      updateConfig("decoration:inactive_opacity", 0.85);
                      } else {
                      updateConfig("decoration:active_opacity", 1);
                      updateConfig("decoration:inactive_opacity", 1);
                    }
                  })
                  .catch(print);
              },
            }),
            HyprlandToggle({
              icon: "blur_on",
              name: getString("Blur"),
              desc: getString(
                "[Hyprland]\nEnable blur on transparent elements.",
              ),
              option: "decoration:blur:enabled",
            }),
            Subcategory([
              HyprlandSpinButton({
                icon: "target",
                name: getString("Blur Size"),
                desc: getString("[Hyprland]\nAdjust the blur radius."),
                option: "decoration:blur:size",
                minValue: 1,
                maxValue: 1000,
              }),
              HyprlandSpinButton({
                icon: "repeat",
                name: getString("Blur Passes"),
                desc: getString(
                  "[Hyprland]\nAdjust the number of passes for blur.",
                ),
                option: "decoration:blur:passes",
                minValue: 1,
                maxValue: 10,
              }),
            ]),
            HyprlandToggle({
              icon: "shadow",
              name: getString("Shadow"),
              desc: getString("[Hyprland]\nEnable shadow on transparent elements.",),
              option: "decoration:shadow:enabled",
            }),
            HyprlandToggle({
              icon: "auto_fix_high",
              name: getString("Blur Special"),
              desc: getString("[Hyprland]\nEnable special blur effects."),
              option: "decoration:blur:special",
            }),
            HyprlandToggle({
              icon: "brightness_2",
              name: getString("Dim Special"),
              desc: getString("[Hyprland]\nEnable special dim effects."),
              option: "decoration:dim_special",
            }),
            ConfigGap({}),
            HyprlandToggle({
              icon: "animation",
              name: getString("Animations"),
              desc: getString("[Hyprland] [GTK]\nEnable animations"),
              option: "animations:enabled",
              extraOnChange: (self, newValue) =>
                execAsync([
                  "gsettings",
                  "set",
                  "org.gnome.desktop.interface",
                  "enable-animations",
                  `${newValue}`,
                ]),
            }),
            Subcategory([
              ConfigSpinButton({
                icon: "clear_all",
                name: getString("Choreography delay"),
                desc: getString(
                  "In milliseconds, the delay between animations of a series",
                ),
                initValue: userOptions.animations.choreographyDelay,
                step: 10,
                minValue: 0,
                maxValue: 1000,
                onChange: (self, newValue) => {
                  userOptions.animations.choreographyDelay = newValue;
                },
              }),
            ]),
          ],
        }),
        // Developer Section
        ConfigSection({
          name: getString("Developer"),
          children: [
            HyprlandToggle({
              icon: "speed",
              name: getString("Show FPS"),
              desc: getString(
                "[Hyprland]\nShow FPS overlay on top-left corner.",
              ),
              option: "debug:overlay",
            }),
            HyprlandToggle({
              icon: "sort",
              name: getString("Log to stdout"),
              desc: getString("[Hyprland]\nPrint log messages to console."),
              option: "debug:enable_stdout_logs",
            }),
            HyprlandToggle({
              icon: "motion_sensor_active",
              name: getString("Damage Tracking"),
              desc: getString("[Hyprland]\nEnable damage tracking."),
              option: "debug:damage_tracking",
              enableValue: 2,
            }),
            HyprlandToggle({
              icon: "destruction",
              name: getString("Damage Blink"),
              desc: getString("[Hyprland]\nShow screen damage flashes."),
              option: "debug:damage_blink",
            }),
          ],
        }),
      ],
    }),
  });

  const footNote = Box({
    homogeneous: true,
    children: [
      Label({
        hpack: "center",
        className: "txt txt-italic txt-subtext margin-5",
        label: getString("Not all changes are saved"),
      }),
    ],
  });

  return Box({
    ...props,
    className: "spacing-v-5",
    vertical: true,
    children: [mainContent, footNote],
  });
};

// Ensure the config file exists before applying changes
ensureConfigFileExists();
