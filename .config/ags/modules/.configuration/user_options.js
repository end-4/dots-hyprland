import userOverrides from '../../user_options.js';

// Default options.
// Add overrides in ~/.config/ags/user_options.js
let configOptions = {
    // General stuff
    'ai': {
        'defaultGPTProvider': "openai",
        'defaultTemperature': 0.9,
        'enhancements': true,
        'useHistory': true,
        'writingCursor': " ...", // Warning: Using weird characters can mess up Markdown rendering
        'proxyUrl': null, // Can be "socks5://127.0.0.1:9050" or "http://127.0.0.1:8080" for example. Leave it blank if you don't need it.
    },
    'animations': {
        'choreographyDelay': 35,
        'durationSmall': 110,
        'durationLarge': 180,
    },
    'appearance': {
        'keyboardUseFlag': false, // Use flag emoji instead of abbreviation letters
        'layerSmoke': false,
        'layerSmokeStrength': 0.2,
        'fakeScreenRounding': true,
    },
    'apps': {
        'bluetooth': "blueberry",
        'imageViewer': "loupe",
        'network': "XDG_CURRENT_DESKTOP=\"gnome\" gnome-control-center wifi",
        'settings': "XDG_CURRENT_DESKTOP=\"gnome\" gnome-control-center wifi",
        'taskManager': "gnome-usage",
        'terminal': "foot", // This is only for shell actions
    },
    'battery': {
        'low': 20,
        'critical': 10,
        'warnLevels': [20, 15, 5],
        'warnTitles': ["Low battery", "Very low battery", 'Critical Battery'],
        'warnMessages': ["Plug in the charger", "You there?", 'PLUG THE CHARGER ALREADY'],
        'suspendThreshold': 3,
    },
    'brightness': {
        // Object of controller names for each monitor, either "brightnessctl" or "ddcutil" or "auto"
        // 'default' one will be used if unspecified
        // Examples
        // 'eDP-1': "brightnessctl",
        // 'DP-1': "ddcutil",
        'controllers': {
            'default': "auto",
        },
    },
    'gaming': {
        'crosshair': {
            'size': 20,
            'color': 'rgba(113,227,32,0.9)',
        },
    },
    'music': {
        'preferredPlayer': "plasma-browser-integration",
    },
    'onScreenKeyboard': {
        'layout': "qwerty_full", // See modules/onscreenkeyboard/onscreenkeyboard.js for available layouts
    },
    'overview': {
        'scale': 0.18, // Relative to screen size
        'numOfRows': 2,
        'numOfCols': 5,
        'wsNumScale': 0.09,
        'wsNumMarginScale': 0.07,
    },
    'sidebar': {
        'imageColumns': 2,
        'imageBooruCount': 20,
        'imageAllowNsfw': false,
    },
    'search': {
        'engineBaseUrl': "https://www.google.com/search?q=",
        'excludedSites': ["quora.com"],
    },
    'time': {
        // See https://docs.gtk.org/glib/method.DateTime.format.html
        // Here's the 12h format: "%I:%M%P"
        // For seconds, add "%S" and set interval to 1000
        'format': "%H:%M",
        'interval': 5000,
        'dateFormatLong': "%A, %d/%m", // On bar
        'dateInterval': 5000,
        'dateFormat': "%d/%m", // On notif time
    },
    'weather': {
        'city': "",
    },
    'workspaces': {
        'shown': 10,
    },
    'dock': {
        'enabled': false,
        'hiddenThickness': 5,
        'pinnedApps': ['firefox', 'org.gnome.Nautilus'],
        'layer': 'top',
        'monitorExclusivity': true, // Dock will move to other monitor along with focus if enabled
        'searchPinnedAppIcons': false, // Try to search for the correct icon if the app class isn't an icon name
        'trigger': ['client-added', 'client-removed'], // client_added, client_move, workspace_active, client_active
        // Automatically hide dock after `interval` ms since trigger
        'autoHide': [
            {
                'trigger': 'client-added',
                'interval': 500,
            },
            {
                'trigger': 'client-removed',
                'interval': 500,
            },
        ],
    },
    // Longer stuff
    'icons': {
        // Find the window's icon by its class with levenshteinDistance
        // The file names are processed at startup, so if there
        // are too many files in the search path it'll affect performance
        // Example: ['/usr/share/icons/Tela-nord/scalable/apps']
        'searchPaths': [''],

        substitutions: {
            'code-url-handler': "visual-studio-code",
            'Code': "visual-studio-code",
            'GitHub Desktop': "github-desktop",
            'Minecraft* 1.20.1': "minecraft",
            'gnome-tweaks': "org.gnome.tweaks",
            'pavucontrol-qt': "pavucontrol",
            'wps': "wps-office2019-kprometheus",
            'wpsoffice': "wps-office2019-kprometheus",
            '': "image-missing",
        },
        regexSubstitutions: [
            {
                regex: /^steam_app_(\d+)$/,
                replace: "steam_icon_$1",
            }
        ]
    },
    'keybinds': {
        // Format: Mod1+Mod2+key. CaSe SeNsItIvE!
        // Modifiers: Shift Ctrl Alt Hyper Meta
        // See https://docs.gtk.org/gdk3/index.html#constants for the other keys (they are listed as KEY_key)
        'overview': {
            'altMoveLeft': "Ctrl+b",
            'altMoveRight': "Ctrl+f",
            'deleteToEnd': "Ctrl+k",
        },
        'sidebar': {
            'apis': {
                'nextTab': "Page_Down",
                'prevTab': "Page_Up",
            },
            'options': { // Right sidebar
                'nextTab': "Page_Down",
                'prevTab': "Page_Up",
            },
            'pin': "Ctrl+p",
            'cycleTab': "Ctrl+Tab",
            'nextTab': "Ctrl+Page_Down",
            'prevTab': "Ctrl+Page_Up",
        },
        'cheatsheet': {
            'nextTab': "Page_Down",
            'prevTab': "Page_Up",
        }
    },
}

// Override defaults with user's options
function overrideConfigRecursive(userOverrides, configOptions = {}) {
    for (const [key, value] of Object.entries(userOverrides)) {
        if (typeof value === 'object') {
            overrideConfigRecursive(value, configOptions[key]);
        } else {
            configOptions[key] = value;
        }
    }
}
overrideConfigRecursive(userOverrides, configOptions);

globalThis['userOptions'] = configOptions;
export default configOptions;
