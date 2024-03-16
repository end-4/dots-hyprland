
import userOverrides from '../../user_options.js';

// Defaults
let configOptions = {
    // General stuff
    'ai': {
        'defaultGPTProvider': "openai",
        'defaultTemperature': 0.9,
        'writingCursor': " ...", // Warning: Using weird characters can mess up Markdown rendering
    },
    'animations': {
        'durationSmall': 110,
        'durationLarge': 180,
    },
    'apps': {
        'imageViewer': "loupe",
        'terminal': "foot", // This is only for shell actions
    },
    'battery': {
        'low': 20,
        'critical': 10,
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
    // Longer stuff
    'icons': {
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
        }
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
            'pin': "Ctrl+p",
            'cycleTab': "Ctrl+Tab",
            'nextTab': "Ctrl+Page_Down",
            'prevTab': "Ctrl+Page_Up",
        },
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