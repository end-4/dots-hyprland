const { App, Service } = ags;
const { execAsync, CONFIG_DIR } = ags.Utils;

async function setupScss() {
    try {
        await execAsync(['sassc', `${CONFIG_DIR}/scss/main.scss`, `${CONFIG_DIR}/style.css`]);
        ags.App.resetCss();
        ags.App.applyCss(`${CONFIG_DIR}/style.css`);
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
    static { Service.export(this, 'Theme'); }
    static instance = new ThemeService();
};