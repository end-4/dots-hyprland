const { Gdk, Gtk } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

import Applications from 'resource:///com/github/Aylur/ags/service/applications.js';
const { execAsync, exec } = Utils;
import { execAndClose, expandTilde, hasUnterminatedBackslash, couldBeMath, launchCustomCommand, ls } from './miscfunctions.js';
import {
    CalculationResultButton, CustomCommandButton, DirectoryButton,
    DesktopEntryButton, ExecuteCommandButton, SearchButton
} from './searchbuttons.js';

// Add math funcs
const { abs, sin, cos, tan, cot, asin, acos, atan, acot } = Math;
const pi = Math.PI;
// trigonometric funcs for deg
const sind = x => sin(x * pi / 180);
const cosd = x => cos(x * pi / 180);
const tand = x => tan(x * pi / 180);
const cotd = x => cot(x * pi / 180);
const asind = x => asin(x) * 180 / pi;
const acosd = x => acos(x) * 180 / pi;
const atand = x => atan(x) * 180 / pi;
const acotd = x => acot(x) * 180 / pi;

const MAX_RESULTS = 10;
const OVERVIEW_SCALE = 0.18; // = overview workspace box / screen size
const OVERVIEW_WS_NUM_SCALE = 0.09;
const OVERVIEW_WS_NUM_MARGIN_SCALE = 0.07;
const TARGET = [Gtk.TargetEntry.new('text/plain', Gtk.TargetFlags.SAME_APP, 0)];

function iconExists(iconName) {
    let iconTheme = Gtk.IconTheme.get_default();
    return iconTheme.has_icon(iconName);
}

const OptionalOverview = async () => {
    try {
        return (await import('./overview_hyprland.js')).default();
    } catch {
        return Widget.Box({});
        // return (await import('./overview_hyprland.js')).default();
    }
};

const overviewContent = await OptionalOverview();

export const SearchAndWindows = () => {
    var _appSearchResults = [];

    const ClickToClose = ({ ...props }) => Widget.EventBox({
        ...props,
        onPrimaryClick: () => App.closeWindow('overview'),
        onSecondaryClick: () => App.closeWindow('overview'),
        onMiddleClick: () => App.closeWindow('overview'),
    });
    const resultsBox = Widget.Box({
        className: 'overview-search-results',
        vertical: true,
        vexpand: true,
    });
    const resultsRevealer = Widget.Revealer({
        transitionDuration: 200,
        revealChild: false,
        transition: 'slide_down',
        // duration: 200,
        hpack: 'center',
        child: resultsBox,
    });
    const entryPromptRevealer = Widget.Revealer({
        transition: 'crossfade',
        transitionDuration: 150,
        revealChild: true,
        hpack: 'center',
        child: Widget.Label({
            className: 'overview-search-prompt txt-small txt',
            label: 'Type to search'
        }),
    });

    const entryIconRevealer = Widget.Revealer({
        transition: 'crossfade',
        transitionDuration: 150,
        revealChild: false,
        hpack: 'end',
        child: Widget.Label({
            className: 'txt txt-large icon-material overview-search-icon',
            label: 'search',
        }),
    });

    const entryIcon = Widget.Box({
        className: 'overview-search-prompt-box',
        setup: box => box.pack_start(entryIconRevealer, true, true, 0),
    });

    const entry = Widget.Entry({
        className: 'overview-search-box txt-small txt',
        hpack: 'center',
        onAccept: (self) => { // This is when you hit Enter
            const text = self.text;
            if (text.length == 0) return;
            const isAction = text.startsWith('>');
            const isDir = (['/', '~'].includes(entry.text[0]));

            if (couldBeMath(text)) { // Eval on typing is dangerous, this is a workaround
                try {
                    const fullResult = eval(text.replace(/\^/g, "**"));
                    // copy
                    execAsync(['wl-copy', `${fullResult}`]).catch(print);
                    App.closeWindow('overview');
                    return;
                } catch (e) {
                    // console.log(e);
                }
            }
            if (isDir) {
                App.closeWindow('overview');
                execAsync(['bash', '-c', `xdg-open "${expandTilde(text)}"`, `&`]).catch(print);
                return;
            }
            if (_appSearchResults.length > 0) {
                App.closeWindow('overview');
                _appSearchResults[0].launch();
                return;
            }
            else if (text[0] == '>') { // Custom commands
                App.closeWindow('overview');
                launchCustomCommand(text);
                return;
            }
            // Fallback: Execute command
            if (!isAction && exec(`bash -c "command -v ${text.split(' ')[0]}"`) != '') {
                if (text.startsWith('sudo'))
                    execAndClose(text, true);
                else
                    execAndClose(text, false);
            }

            else {
                App.closeWindow('overview');
                execAsync(['bash', '-c', `xdg-open 'https://www.google.com/search?q=${text} -site:quora.com' &`]).catch(print); // quora is useless
            }
        },
        onChange: (entry) => { // this is when you type
            const isAction = entry.text[0] == '>';
            const isDir = (['/', '~'].includes(entry.text[0]));
            resultsBox.get_children().forEach(ch => ch.destroy());

            // check empty if so then dont do stuff
            if (entry.text == '') {
                resultsRevealer.revealChild = false;
                overviewContent.revealChild = true;
                entryPromptRevealer.revealChild = true;
                entryIconRevealer.revealChild = false;
                entry.toggleClassName('overview-search-box-extended', false);
                return;
            }
            const text = entry.text;
            resultsRevealer.revealChild = true;
            overviewContent.revealChild = false;
            entryPromptRevealer.revealChild = false;
            entryIconRevealer.revealChild = true;
            entry.toggleClassName('overview-search-box-extended', true);
            _appSearchResults = Applications.query(text);

            // Calculate
            if (couldBeMath(text)) { // Eval on typing is dangerous; this is a small workaround.
                try {
                    const fullResult = eval(text.replace(/\^/g, "**"));
                    resultsBox.add(CalculationResultButton({ result: fullResult, text: text }));
                } catch (e) {
                    // console.log(e);
                }
            }
            if (isDir) {
                var contents = [];
                contents = ls({ path: text, silent: true });
                contents.forEach((item) => {
                    resultsBox.add(DirectoryButton(item));
                })
            }
            if (isAction) { // Eval on typing is dangerous, this is a workaround.
                resultsBox.add(CustomCommandButton({ text: entry.text }));
            }
            // Add application entries
            let appsToAdd = MAX_RESULTS;
            _appSearchResults.forEach(app => {
                if (appsToAdd == 0) return;
                resultsBox.add(DesktopEntryButton(app));
                appsToAdd--;
            });

            // Fallbacks
            // if the first word is an actual command
            if (!isAction && !hasUnterminatedBackslash(text) && exec(`bash -c "command -v ${text.split(' ')[0]}"`) != '') {
                resultsBox.add(ExecuteCommandButton({ command: entry.text, terminal: entry.text.startsWith('sudo') }));
            }

            // Add fallback: search
            resultsBox.add(SearchButton({ text: entry.text }));
            resultsBox.show_all();
        },
    });
    return Widget.Box({
        vertical: true,
        children: [
            ClickToClose({ // Top margin. Also works as a click-outside-to-close thing
                child: Widget.Box({
                    className: 'bar-height',
                })
            }),
            Widget.Box({
                hpack: 'center',
                children: [
                    entry,
                    Widget.Box({
                        className: 'overview-search-icon-box',
                        setup: (box) => {
                            box.pack_start(entryPromptRevealer, true, true, 0)
                            // enableClickthrough(box);
                        },
                    }),
                    entryIcon,
                ]
            }),
            overviewContent,
            resultsRevealer,
        ],
        setup: (self) => self
            .hook(App, (_b, name, visible) => {
                if (name == 'overview' && !visible) {
                    resultsBox.children = [];
                    entry.set_text('');
                }
            })
            .on('key-press-event', (widget, event) => { // Typing
                const keyval = event.get_keyval()[1];
                const modstate = event.get_state()[1];
                if (modstate & Gdk.ModifierType.CONTROL_MASK) { // Ctrl held
                    if (keyval == Gdk.KEY_b) 
                        entry.set_position(Math.max(entry.get_position() - 1, 0));
                    else if (keyval == Gdk.KEY_f)
                        entry.set_position(Math.min(entry.get_position() + 1, entry.get_text().length));
                    else if (keyval == Gdk.KEY_n) { // simulate Down arrow
                        entry.get_root_window().simulate_key_press(Gdk.KEY_Down, Gdk.ModifierType.NONE);
                        // entry.get_root_window().simulate_key_release(Gdk.KEY_Down, Gdk.ModifierType.NONE);
                    }
                    else if (keyval == Gdk.KEY_k) { // Delete to end
                        const text = entry.get_text();
                        const pos = entry.get_position();
                        const newText = text.slice(0, pos);
                        entry.set_text(newText);
                        entry.set_position(newText.length);
                    }
                }
                else { // Ctrl not held
                    if (keyval >= 32 && keyval <= 126 && widget != entry) {
                        Utils.timeout(1, () => entry.grab_focus());
                        entry.set_text(entry.text + String.fromCharCode(keyval));
                        entry.set_position(-1);
                    }
                }
            })
        ,
    });
}; 
