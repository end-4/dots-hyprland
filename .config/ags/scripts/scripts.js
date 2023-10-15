import { App, Service, Utils, Widget } from '../imports.js';
const { exec, execAsync, CONFIG_DIR } = Utils;

export const deflisten = function (name, command, transformer = (a) => a) {
    const { Service } = ags;
    const GObject = imports.gi.GObject;

    const v = GObject.registerClass(
        {
            GTypeName: name,
            Properties: {
                state: GObject.ParamSpec.string(
                    "state",
                    "State",
                    "Read-Write string state.",
                    GObject.ParamFlags.READWRITE,
                    ""
                ),
            },
            Signals: {
                [`${name}-changed`]: {},
            },
        },
        class Subclass extends Service {
            get state() {
                return this._state || "";
            }

            set state(value) {
                this._state = value;
                this.emit("changed");
            }

            get proc() {
                return this._proc || null;
            }

            set proc(value) {
                this._proc = value;
            }

            start = () => {
                this.proc = Utils.subprocess(command, (line) => {
                    this.state = transformer(line);
                });
            }

            stop = () => {
                this.proc.force_exit();
                this.proc = null;
            }

            constructor() {
                super();
                this.proc = Utils.subprocess(command, (line) => {
                    this.state = transformer(line);
                });
            }
        }
    );

    class State {
        static {
            globalThis[name] = this;
        }

        static instance = new v();

        static get state() {
            return State.instance.state;
        }

        static set state(value) {
            State.instance.state = value;
        }

        static start() {
            State.instance.start();
        }
        static stop() {
            State.instance.stop();
        }
    }

    return State;
}

export async function switchWall() {
    try {
        path = exec(`bash -c 'cd ~/Pictures && yad --width 1200 --height 800 --file --title="Choose wallpaper"'`);
        screensizey = JSON.parse(exec(`hyprctl monitors -j`))[0]['height'];
        cursorposx = exec(`bash -c 'hyprctl cursorpos -j | gojq ".x"'`);
        cursorposy = exec(`bash -c 'hyprctl cursorpos -j | gojq ".y"'`);
        cursorposy_inverted = screensizey - cursorposy;
        // print all those
        if (path == '') {
            print('Switch wallpaper: Aborted');
            return;
        }
        print(`Sending ${path} to swww. Cursor pos: [${cursorposx}, ${cursorposy_inverted}]`);
        exec(`swww img ${path} --transition-step 230 --transition-fps 60 --transition-type grow --transition-angle 30 --transition-duration 1 --transition-pos "${cursorposx}, ${cursorposy_inverted}"`);
        exec(CONFIG_DIR + `/scripts/colorgen.sh ${path} --apply`);
        imports.scss.scss.setupScss();
    } catch (error) {
        print(error);
    }
}
