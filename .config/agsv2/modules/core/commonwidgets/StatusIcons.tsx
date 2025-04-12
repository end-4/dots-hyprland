import { App, Astal, Gtk } from 'astal/gtk3';
import { Revealer, BoxProps, Label } from 'astal/gtk3/widget';
import { MaterialIcon } from './MaterialIcon';
import { userOptions } from '../configuration/user_options';
import Wp from 'gi://AstalWp';
import { bind, exec, Variable } from 'astal';
import AstalNetwork from 'gi://AstalNetwork';
import AstalBluetooth from 'gi://AstalBluetooth';
import AstalNotifd from 'gi://AstalNotifd';
import { languages } from './statusicons_languages';

const network = AstalNetwork.get_default();
const bluetooth = AstalBluetooth.get_default();
const notifd = AstalNotifd.get_default();

// A guessing func to try to support langs not listed in data/languages.js
function isLanguageMatch(abbreviation: string, word: string) {
    const lowerAbbreviation = abbreviation.toLowerCase();
    const lowerWord = word.toLowerCase();
    let j = 0;
    for (let i = 0; i < lowerWord.length; i++) {
        if (lowerWord[i] === lowerAbbreviation[j]) {
            j++;
        }
        if (j === lowerAbbreviation.length) {
            return true;
        }
    }
    return false;
}

function MicMuteIndicator() {
    const audio = Wp.get_default()!.audio;
    let revealer: Revealer;

    bind(audio, 'defaultMicrophone').subscribe((mic) => setup(revealer, mic));

    function setup(self: Revealer, mic = audio.defaultMicrophone) {
        revealer = self;
        if (!mic) return (revealer.revealChild = true);
        revealer.revealChild = mic.mute;
        bind(mic, 'mute').subscribe((mute) => (revealer.revealChild = mute));
    }

    return (
        <revealer
            transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
            transitionDuration={userOptions.animations.durationSmall}
            setup={setup}
        >
            <MaterialIcon icon="mic_off" size="norm" />
        </revealer>
    );
}

function NotificationIndicator({ notifCenterName = 'sideright' }: { notifCenterName?: string }) {
    let revealer: Revealer;
    let label: Label;
    let status: Record<number, boolean> = {};

    const handles = Variable.derive(
        [bind(notifd, 'notifications'), bind(notifd, 'dontDisturb'), bind(App, 'activeWindow')],
        (notifications, dontDisturb, activeWindow) => {
            return { notifications, dontDisturb, activeWindow };
        }
    );

    handles.subscribe((n) => setup(revealer, n.notifications, n.dontDisturb));

    function setup(
        self: Revealer,
        notifications = notifd.notifications,
        dontDisturb = notifd.dontDisturb,
        activeWindow = App.activeWindow
    ) {
        revealer = self;
        const oldStatus: Record<number, boolean> = status;
        const newStatus: Record<number, boolean> = {};
        let unread = 0;
        notifications.forEach((notification) => {
            newStatus[notification.id] =
                activeWindow?.name === notifCenterName || (oldStatus[notification.id] ?? false);
            if (!newStatus[notification.id]) unread++;
        });
        status = newStatus;
        if (unread === 0 || dontDisturb) return (revealer.revealChild = false);
        revealer.revealChild = true;
        label.label = String(unread);
    }

    return (
        <revealer
            transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
            transitionDuration={userOptions.animations.durationSmall}
            setup={setup}
            onDestroy={handles.drop}
        >
            <box>
                <MaterialIcon icon="notifications" size="norm" />
                <label className="txt-small titlefont" setup={(self) => (label = self)} />
            </box>
        </revealer>
    );
}

function BluetoothIndicator() {
    let stack: Astal.Stack;

    const status = Variable.derive(
        [bind(bluetooth, 'isPowered'), bind(bluetooth, 'isConnected')],
        (powered, connected) => {
            return { powered, connected };
        }
    );

    status.subscribe((status) => setup(stack, status.powered, status.connected));

    function setup(self: Astal.Stack, powered = bluetooth.isPowered, connected = bluetooth.isConnected) {
        stack = self;
        if (!powered) stack.shown = 'disabled';
        else if (!connected) stack.shown = 'enabled';
        else stack.shown = 'connected';
    }

    return (
        <stack
            transitionType={Gtk.StackTransitionType.SLIDE_UP_DOWN}
            transitionDuration={userOptions.animations.durationSmall}
            setup={setup}
            onDestroy={status.drop}
        >
            <label name="disabled" className="txt-norm icon-material" label="bluetooth_disabled" />
            <label name="enabled" className="txt-norm icon-material" label="bluetooth" />
            <label name="connected" className="txt-norm icon-material" label="bluetooth_connected" />
        </stack>
    );
}

function BluetoothDevices() {
    function BluetoothDevice(device: AstalBluetooth.Device) {
        return (
            <box className="bar-bluetooth-device spacing-h-5" valign={Gtk.Align.CENTER} tooltipText={device.name}>
                <icon iconName={`${device.icon}-symbolic`} />
                {device.batteryPercentage ?? (
                    <label className="txt-smallie" label={bind(device, 'batteryPercentage').as(String)} />
                )}
            </box>
        );
    }

    return (
        <box className="spacing-h-5">
            {bind(bluetooth, 'devices').as((devices) => {
                return devices.map(BluetoothDevice);
            })}
        </box>
    );
}

function NetworkWiredIndicator({ name }: { name: string }) {
    const status = Variable.derive([bind(network, 'wired'), bind(network, 'connectivity')], (wired, connectivity) => {
        return { wired, connectivity };
    });
    let stack: Astal.Stack;

    status.subscribe((status) => setup(stack, status.wired, status.connectivity));

    function setup(self: Astal.Stack, wired = network.wired, connectivity = network.connectivity) {
        stack = self;
        if (!wired) return (stack.shown = 'fallback');
        const { internet } = wired;
        if (internet === AstalNetwork.Internet.CONNECTING) stack.shown = 'connecting';
        else if (internet === AstalNetwork.Internet.CONNECTED) stack.shown = 'connected';
        else if (connectivity !== AstalNetwork.Connectivity.FULL) stack.shown = 'disconnected';
        else stack.shown = 'fallback';
    }

    return (
        <stack
            name={name}
            transitionType={Gtk.StackTransitionType.SLIDE_UP_DOWN}
            transitionDuration={userOptions.animations.durationSmall}
            setup={setup}
            onDestroy={status.drop}
        >
            <SimpleNetworkIndicator name="fallback" />
            <label name="unknown" className={'txt-norm icon-material'} label={'wifi_off'} />
            <label name="disconnected" className={'txt-norm icon-material'} label={'signal_wifi_off'} />
            <label name="connected" className={'txt-norm icon-material'} label={'lan'} />
            <label name="connecting" className={'txt-norm icon-material'} label={'settings_ethernet'} />
        </stack>
    );
}

function SimpleNetworkIndicator({ name }: { name: string }) {
    return <icon name={name} icon={bind(AstalNetwork.get_default(), 'wifi').as((wifi) => wifi.iconName)} />;
}

function NetworkWifiIndicator({ name }: { name: string }) {
    let stack: Astal.Stack;

    bind(network, 'wifi').subscribe((wifi) => setup(stack, wifi));

    function setup(self: Astal.Stack, wifi = network.wifi) {
        stack = self;
        if (!wifi) return (stack.shown = '');
        const { internet, enabled } = wifi;
        if (!enabled) stack.shown = 'disabled';
        else if (internet === AstalNetwork.Internet.CONNECTED) stack.shown = String(Math.ceil(wifi.strength / 25));
        else if (internet === AstalNetwork.Internet.DISCONNECTED) stack.shown = 'disconnected';
        else if (internet === AstalNetwork.Internet.CONNECTING) stack.shown = 'connecting';
    }

    return (
        <stack
            name={name}
            transitionType={Gtk.StackTransitionType.SLIDE_UP_DOWN}
            transitionDuration={userOptions.animations.durationSmall}
            setup={setup}
        >
            <label name="disabled" className="txt-norm icon-material" label="signal_wifi_off" />
            <label name="disconnected" className="txt-norm icon-material" label="signal_wifi_statusbar_not_connected" />
            <label name="connecting" className="txt-norm icon-material" label="settings_ethernet" />
            <label name="0" className="txt-norm icon-material" label="signal_wifi_0_bar" />
            <label name="1" className="txt-norm icon-material" label="network_wifi_1_bar" />
            <label name="2" className="txt-norm icon-material" label="network_wifi_2_bar" />
            <label name="3" className="txt-norm icon-material" label="network_wifi_3_bar" />
            <label name="4" className="txt-norm icon-material" label="signal_wifi_4_bar" />
        </stack>
    );
}

function NetworkIndicator() {
    let stack: Astal.Stack;

    bind(network, 'primary').subscribe((primary) => setup(stack, primary));

    function setup(self: Astal.Stack, primary = network.primary) {
        stack = self;
        if (!primary) return (stack.shown = 'fallback');
        if (primary === AstalNetwork.Primary.WIFI) stack.shown = 'wifi';
        else if (primary === AstalNetwork.Primary.WIRED) stack.shown = 'wired';
        else stack.shown = 'fallback';
    }

    return (
        <stack
            transitionType={Gtk.StackTransitionType.SLIDE_UP_DOWN}
            transitionDuration={userOptions.animations.durationSmall}
            setup={setup}
        >
            <SimpleNetworkIndicator name="fallback" />
            <NetworkWifiIndicator name="wifi" />
            <NetworkWiredIndicator name="wired" />
        </stack>
    );
}

function HyprlandXkbKeyboardLayout({ useFlag = userOptions.appearance.keyboardUseFlag }: { useFlag?: boolean } = {}) {
    try {
        const keyboardLanguages: string[] = JSON.parse(exec('hyprctl -j getoption input:kb_layout')).str.split(',');
        // TODO: React to keyboard layout changes
        const keyboards: { main: boolean; active_keymap: string }[] = JSON.parse(exec('hyprctl -j devices')).keyboards;
        const activeKeymap = keyboards.find((keyboard) => keyboard.main)!.active_keymap;
        let activeLayout = languages.find((lang) => activeKeymap.includes(lang.name))?.layout;
        if (!activeLayout) {
            // Attempt to support langs not listed
            activeLayout = keyboardLanguages.find((lang) => isLanguageMatch(lang[0], activeKeymap));
        }

        return (
            <revealer
                transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
                transitionDuration={userOptions.animations.durationSmall}
                revealChild={keyboardLanguages.length > 1}
            >
                <stack
                    transitionType={Gtk.StackTransitionType.SLIDE_UP_DOWN}
                    transitionDuration={userOptions.animations.durationSmall}
                    shown={activeLayout}
                >
                    <label name="undef" label="?" />
                    {keyboardLanguages.map((keyboardLanguage) => {
                        const lang = languages.find((lang) => lang.layout == keyboardLanguage);
                        return <label name={keyboardLanguage} label={useFlag && lang ? lang.flag : keyboardLanguage} />;
                    })}
                </stack>
            </revealer>
        );
    } catch {
        return <label />;
    }
}

export default function StatusIcons({ ...args }: BoxProps) {
    return (
        <box {...args}>
            <box className="spacing-h-15">
                <MicMuteIndicator />
                <HyprlandXkbKeyboardLayout />
                <NotificationIndicator />
                <NetworkIndicator />
                <box className="spacing-h-5">
                    <BluetoothIndicator />
                    <BluetoothDevices />
                </box>
            </box>
        </box>
    );
}
