const { App, Service, Utils } = ags;
const { execAsync, CONFIG_DIR } = Utils;

async function setupScss() {
    try {
        await execAsync(['sassc', `${CONFIG_DIR}/scss/main.scss`, `${CONFIG_DIR}/style.css`]);
        App.resetCss();
        App.applyCss(`${CONFIG_DIR}/style.css`);
    } catch (error) {
        print(error);
    }
}

class ThemeService extends Service {
    static { Service.register(this); }

    constructor() {
        super();
        this.setup();
    }

    setup() {
        setupScss();
    }
}

var Theme = class Theme {
    static { globalThis['Theme'] = this; }
    static instance = new ThemeService();
};