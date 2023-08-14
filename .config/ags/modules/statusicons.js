const { Widget, Service } = ags;
const { exec, execAsync } = ags.Utils;
const { Audio, Battery, Bluetooth, Network } = ags.Service;

const icons = [
    { value: 80, widget: { type: 'label', className: 'txt-norm icon-material', label: 'signal_wifi_4_bar' } },
    { value: 60, widget: { type: 'label', className: 'txt-norm icon-material', label: 'network_wifi_3_bar' } },
    { value: 40, widget: { type: 'label', className: 'txt-norm icon-material', label: 'network_wifi_2_bar' } },
    { value: 20, widget: { type: 'label', className: 'txt-norm icon-material', label: 'network_wifi_1_bar' } },
    { value: 0,  widget: { type: 'label', className: 'txt-norm icon-material', label: 'signal_wifi_0_bar' } },
];

Widget.widgets['bluetooth/indicator'] = ({
    enabled = { type: 'label', className: 'txt-norm icon-material', label: 'bluetooth' },
    disabled = { type: 'label', className: 'txt-norm icon-material', label: 'bluetooth_disabled' },
    ...props
}) => Widget({
    ...props,
    type: 'dynamic',
    items: [
        { value: true, widget: enabled },
        { value: false, widget: disabled },
    ],
    connections: [[Bluetooth, dynamic => dynamic.update(value => value === Bluetooth.enabled)]],
});

Widget.widgets['network/wired-indicator'] = ({
    disabled = { type: 'label', className: 'txt-norm icon-material', label: 'wifi_off' },
    disconnected = { type: 'label', className: 'txt-norm icon-material', label: 'signal_wifi_off' },
    connecting = { type: 'label', className: 'txt-norm icon-material', label: 'signal_wifi_statusbar_not_connected' },
    connected = { type: 'label', className: 'txt-norm icon-material', label: 'lan' },
    unknown = { type: 'label', className: 'icon-material', label: 'signal_wifi_0_bar' },
}) => Widget({
    type: 'dynamic',
    items: [
        { value: 'unknown', widget: unknown },
        { value: 'disconnected', widget: disconnected },
        { value: 'disabled', widget: disabled },
        { value: 'connected', widget: connected },
        { value: 'connecting', widget: connecting },
    ],
    connections: [[Network, dynamic => dynamic.update(value => {
        if (!Network.wired)
            return;

        const { internet } = Network.wired;
        if (internet === 'connected' || internet === 'connecting')
            return value === internet;

        if (Network.connectivity !== 'full')
            return value === 'disconnected';

        return value === 'disabled';
    })]],
});

Widget.widgets['network/wifi-indicator'] = ({
    disabled = { type: 'label', className: 'txt-norm icon-material', label: 'wifi_off' },
    disconnected = { type: 'label', className: 'txt-norm icon-material', label: 'signal_wifi_off' },
    connecting = { type: 'label', className: 'txt-norm icon-material', label: 'signal_wifi_statusbar_not_connected' },
    connected = icons,
}) => Widget({
    type: 'dynamic',
    items: [
        { value: 'disabled', widget: disabled },
        { value: 'disconnected', widget: disconnected },
        { value: 'connecting', widget: connecting },
        ...connected,
    ],
    connections: [[Network, dynamic => dynamic.update(value => {
        if (!Network.wifi)
            return;

        const { internet, enabled, strength } = Network.wifi;
        if (internet === 'connected')
            return value <= strength;

        if (internet === 'connecting')
            return value === 'connecting';

        if (enabled)
            return value === 'disconnected';

        return value === 'disabled';
    })]],
});

Widget.widgets['network/indicator'] = ({
    wifi = { type: 'network/wifi-indicator' },
    wired = { type: 'network/wired-indicator' },
}) => Widget({
    type: 'dynamic',
    items: [
        { value: 'wired', widget: wired },
        { value: 'wifi', widget: wifi },
    ],
    connections: [[Network, dynamic => {
        const primary = Network.primary || 'wifi';
        dynamic.update(value => value === primary);
    }]],
});

Widget.widgets['audio/speaker-indicator'] = ({
    items = [
        { value: 101, widget: { type: 'icon', icon: 'audio-volume-overamplified-symbolic' } },
        { value: 67, widget: { type: 'icon', icon: 'audio-volume-high-symbolic' } },
        { value: 34, widget: { type: 'icon', icon: 'audio-volume-medium-symbolic' } },
        { value: 1, widget: { type: 'icon', icon: 'audio-volume-low-symbolic' } },
        { value: 0, widget: { type: 'icon', icon: 'audio-volume-muted-symbolic' } },
    ],
    ...props
}) => Widget({
    ...props,
    type: 'dynamic',
    items,
    connections: [[Audio, dynamic => dynamic.update(value => {
        if (!Audio.speaker)
            return;

        if (Audio.speaker.isMuted)
            return value === 0;

        return value <= (Audio.speaker.volume * 100);
    }), 'speaker-changed']],
});

Widget.widgets['modules/statusicons'] = () => Widget({
    type: 'eventbox',
    child: {type: 'box',
    className: 'spacing-h-15',
    children: [
        { type: 'bluetooth/indicator', disabled: null },
        { type: 'network/indicator' },
    ]}
});