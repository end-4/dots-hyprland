import { Astal, Gdk, Gtk } from 'astal/gtk3';
import { userOptions } from '../../core/configuration/user_options';
import AstalTray from 'gi://AstalTray';
import { bind, Gio, Variable } from 'astal';
import { Box } from 'astal/gtk3/widget';

const tray = AstalTray.get_default();

function Menu(menuModel: Gio.MenuModel, actionGroup: Gio.ActionGroup) {
    const menu = Gtk.Menu.new_from_model(menuModel);
    menu.insert_action_group('dbusmenu', actionGroup);
    return menu;
}

function SysTrayItem(item: AstalTray.TrayItem) {
    let menu: Gtk.Menu;

    const entryBinding = Variable.derive(
        [bind(item, 'menuModel'), bind(item, 'actionGroup')],
        (menuModel, actionGroup) => {
            if (!menuModel) {
                return console.error(`Menu Model not found for ${item.id}`);
            }
            if (!actionGroup) {
                return console.error(`Action Group not found for ${item.id}`);
            }

            menu = Menu(menuModel, actionGroup);
        }
    );

    function onClick(self: Astal.Button, event: Astal.ClickEvent) {
        switch (event.button) {
            case Astal.MouseButton.PRIMARY:
                item.activate(0, 0);
                break;
            case Astal.MouseButton.SECONDARY: {
                menu!.popup_at_widget(self, Gdk.Gravity.NORTH, Gdk.Gravity.SOUTH, null);
                break;
            }
        }
        return true;
    }

    return (
        <button className="bar-systray-item" onClick={onClick} onDestroy={entryBinding.drop}>
            <icon halign={Gtk.Align.CENTER} gicon={item.gicon} tooltipMarkup={bind(item, 'tooltipMarkup')} />
        </button>
    );
}

export default function Tray() {
    let container: Box;

    bind(tray, 'items').subscribe((items) => setup(container, items));

    function setup(self: Box, items = tray.items) {
        container = self;
        if (items == null) return (container.children = []);
        // Make sure to stop AGS v1 in case items are not showing because:
        // > The agsv1 tray is not compatible with the astal tray, you cant run both at the same time.
        // https://github.com/Aylur/astal/issues/105
        const filtered = items.filter((item) => item.gicon);
        container.children = filtered.map(SysTrayItem);
    }

    return (
        <box>
            <revealer
                revealChild={true}
                transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
                transitionDuration={userOptions.animations.durationLarge}
            >
                <box className="margin-right-5 spacing-h-15" setup={setup} />
            </revealer>
        </box>
    );
}
