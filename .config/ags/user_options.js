
let userConfigOptions = {
    'ai': {
        'defaultGPTProvider': 'openai',
        'defaultTemperature': 0.9,
        'writingCursor': '  ...', // Warning: Using weird characters can mess up Markdown rendering
    },
    'apps': {
        'imageViewer': 'loupe',
    },
    'battery': {
        'low': 20,
        'critical': 10,
    },
    'music': {
        'preferredPlayer': 'plasma-browser-integration',
    },
    'onScreenKeyboard': {
        'layout': 'qwerty_full', // See modules/onscreenkeyboard/onscreenkeyboard.js for available layouts
    },
    'overview': {
        'scale': 0.18,
        'numOfRows': 2,
        'numOfCols': 5,
        'wsNumScale': 0.09,
        'wsNumMarginScale': 0.07,
    },
    'search': {
        'excludedSites': ['quora.com'],
    },
    'weather': {
        'city': '',
    },
    'workspaces': {
        'shown': 10,
    },
    icons: {
        substitutions: {
            'code-url-handler': 'visual-studio-code',
            'Code': 'visual-studio-code',
            'GitHub Desktop': 'github-desktop',
            'wps': 'wps-office2019-kprometheus',
            'gnome-tweaks': 'org.gnome.tweaks',
            'Minecraft* 1.20.1': 'minecraft',
            '': 'image-missing',
        }
    }
}

globalThis['userOptions'] = userConfigOptions;
export default userOptions;