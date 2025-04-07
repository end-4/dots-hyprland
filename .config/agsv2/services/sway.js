import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import Service from "resource:///com/github/Aylur/ags/service.js";

const SIS = GLib.getenv('SWAYSOCK');

export const PAYLOAD_TYPE = {
    MESSAGE_RUN_COMMAND: 0,
    MESSAGE_GET_WORKSPACES: 1,
    MESSAGE_SUBSCRIBE: 2,
    MESSAGE_GET_OUTPUTS: 3,
    MESSAGE_GET_TREE: 4,
    MESSAGE_GET_MARKS: 5,
    MESSAGE_GET_BAR_CONFIG: 6,
    MESSAGE_GET_VERSION: 7,
    MESSAGE_GET_BINDING_NODES: 8,
    MESSAGE_GET_CONFIG: 9,
    MESSAGE_SEND_TICK: 10,
    MESSAGE_SYNC: 11,
    MESSAGE_GET_BINDING_STATE: 12,
    MESSAGE_GET_INPUTS: 100,
    MESSAGE_GET_SEATS: 101,
    EVENT_WORKSPACE: 0x80000000,
    EVENT_MODE: 0x80000002,
    EVENT_WINDOW: 0x80000003,
    EVENT_BARCONFIG_UPDATE: 0x80000004,
    EVENT_BINDING: 0x80000005,
    EVENT_SHUTDOWN: 0x80000006,
    EVENT_TICK: 0x80000007,
    EVENT_BAR_STATE_UPDATE: 0x80000014,
    EVENT_INPUT: 0x80000015,
}

const Client_Event = {
    change: undefined,
    container: undefined,
}

const Workspace_Event = {
    change: undefined,
    current: undefined,
    old: undefined,
}

const Geometry = {
    x: undefined,
    y: undefined,
    width: undefined,
    height: undefined,
}

//NOTE: not all properties are listed here
export const Node = {
    id: undefined,
    name: undefined,
    type: undefined,
    border: undefined,
    current_border_width: undefined,
    layout: undefined,
    orientation: undefined,
    percent: undefined,
    rect: undefined,
    window_rect: undefined,
    deco_rect: undefined,
    geometry: undefined,
    urgent: undefined,
    sticky: undefined,
    marks: undefined,
    focused: undefined,
    active: undefined,
    focus: undefined,
    nodes: undefined,
    floating_nodes: undefined,
    representation: undefined,
    fullscreen_mode: undefined,
    app_id: undefined,
    pid: undefined,
    visible: undefined,
    shell: undefined,
    output: undefined,
    inhibit_idle: undefined,
    idle_inhibitors: {
        application: undefined,
        user: undefined,
    },
    window: undefined,
    window_properties: {
        title: undefined,
        class: undefined,
        instance: undefined,
        window_role: undefined,
        window_type: undefined,
        transient_for: undefined,
    }
}

export class SwayActiveClient extends Service {
    static {
        Service.register(this, {}, {
            'id': ['int'],
            'name': ['string'],
            'class': ['string'],
        });
    }

    _id = 0;
    _name = '';
    _class = '';

    get id() { return this._id; }
    get name() { return this._name; }
    get class() { return this._class; }

    updateProperty(prop, value) {
        if (!['id', 'name', 'class'].includes(prop)) return;
        super.updateProperty(prop, value);
        this.emit('changed');
    }
}

export class SwayActiveID extends Service {
    static {
        Service.register(this, {}, {
            'id': ['int'],
            'name': ['string'],
        });
    }

    _id = 0;
    _name = '';

    get id() { return this._id; }
    get name() { return this._name; }

    update(id, name) {
        super.updateProperty('id', id);
        super.updateProperty('name', name);
        this.emit('changed');
    }
}

export class SwayActives extends Service {
    static {
        Service.register(this, {}, {
            'client': ['jsobject'],
            'monitor': ['jsobject'],
            'workspace': ['jsobject'],
        });
    }

    _client = new SwayActiveClient;
    _monitor = new SwayActiveID;
    _workspace = new SwayActiveID;

    constructor() {
        super();

        (['client', 'workspace', 'monitor']).forEach(obj => {
            this[`_${obj}`].connect('changed', () => {
                this.notify(obj);
                this.emit('changed');
            });
        });
    }

    get client() { return this._client; }
    get monitor() { return this._monitor; }
    get workspace() { return this._workspace; }
}

export class Sway extends Service {
    static {
        Service.register(this, {}, {
            'active': ['jsobject'],
            'monitors': ['jsobject'],
            'workspaces': ['jsobject'],
            'clients': ['jsobject'],
        });
    }

    _decoder = new TextDecoder();
    _encoder = new TextEncoder();
    _socket;

    _active;
    _monitors;
    _workspaces;
    _clients;

    get active() { return this._active; }
    get monitors() { return Array.from(this._monitors.values()); }
    get workspaces() { return Array.from(this._workspaces.values()); }
    get clients() { return Array.from(this._clients.values()); }

    getMonitor(id) { return this._monitors.get(id); }
    getWorkspace(name) { return this._workspaces.get(name); }
    getClient(id) { return this._clients.get(id); }

    msg(payload) { this._send(PAYLOAD_TYPE.MESSAGE_RUN_COMMAND, payload); }

    constructor() {
        if (!SIS)
            console.error('Sway is not running');
        super();

        this._active = new SwayActives();
        this._monitors = new Map();
        this._workspaces = new Map();
        this._clients = new Map();

        this._socket = new Gio.SocketClient().connect(new Gio.UnixSocketAddress({
            path: `${SIS}`,
        }), null);

        this._watchSocket(this._socket.get_input_stream());
        this._send(PAYLOAD_TYPE.MESSAGE_GET_TREE, '');
        this._send(PAYLOAD_TYPE.MESSAGE_SUBSCRIBE, JSON.stringify(['window', 'workspace']));

        this._active.connect('changed', () => this.emit('changed'));
        ['monitor', 'workspace', 'client'].forEach(active =>
            this._active.connect(`notify::${active}`, () => this.notify('active')));
    }

    _send(payloadType, payload) {
        const pb = this._encoder.encode(payload);
        const type = new Uint32Array([payloadType]);
        const pl = new Uint32Array([pb.length]);
        const magic_string = this._encoder.encode('i3-ipc');
        const data = new Uint8Array([
            ...magic_string,
            ...(new Uint8Array(pl.buffer)),
            ...(new Uint8Array(type.buffer)),
            ...pb]);
        this._socket.get_output_stream().write(data, null);
    }

    _watchSocket(stream) {
        stream.read_bytes_async(14, GLib.PRIORITY_DEFAULT, null, (_, resultHeader) => {
            const data = stream.read_bytes_finish(resultHeader).get_data();
            if (!data)
                return;
            const payloadLength = new Uint32Array(data.slice(6, 10).buffer)[0];
            const payloadType = new Uint32Array(data.slice(10, 14).buffer)[0];
            stream.read_bytes_async(
                payloadLength,
                GLib.PRIORITY_DEFAULT,
                null,
                (_, resultPayload) => {
                    const data = stream.read_bytes_finish(resultPayload).get_data();
                    if (!data)
                        return;
                    this._onEvent(payloadType, JSON.parse(this._decoder.decode(data)));
                    this._watchSocket(stream);
                });
        });
    }

    async _onEvent(event_type, event) {
        if (!event)
            return;
        try {
            switch (event_type) {
                case PAYLOAD_TYPE.EVENT_WORKSPACE:
                    this._handleWorkspaceEvent(event);
                    break;
                case PAYLOAD_TYPE.EVENT_WINDOW:
                    this._handleWindowEvent(event);
                    break;
                case PAYLOAD_TYPE.MESSAGE_GET_TREE:
                    this._handleTreeMessage(event);
                    break;
                default:
                    break;
            }
        } catch (error) {
            logError(error);
        }
        this.emit('changed');
    }

    _handleWorkspaceEvent(workspaceEvent) {
        const workspace = workspaceEvent.current;
        switch (workspaceEvent.change) {
            case 'init':
                this._workspaces.set(workspace.name, workspace);
                break;
            case 'empty':
                this._workspaces.delete(workspace.name);
                break;
            case 'focus':
                this._active.workspace.update(workspace.id, workspace.name);
                this._active.monitor.update(1, workspace.output);

                this._workspaces.set(workspace.name, workspace);
                this._workspaces.set(workspaceEvent.old.name, workspaceEvent.old);
                break;
            case 'rename':
                if (this._active.workspace.id === workspace.id)
                    this._active.workspace.updateProperty('name', workspace.name);
                this._workspaces.set(workspace.name, workspace);
                break;
            case 'reload':
                break;
            case 'move':
            case 'urgent':
            default:
                this._workspaces.set(workspace.name, workspace);
        }
        this.notify('workspaces');
    }

    _handleWindowEvent(clientEvent) {
        const client = clientEvent.container;
        const id = client.id;
        switch (clientEvent.change) {
            case 'new':
            case 'close':
            case 'floating':
            case 'move':
                // Refresh tree since client events don't contain the relevant information
                // to be able to modify `workspace.nodes` or `workspace.floating_nodes`.
                // There has to be a better way than this though :/
                this._send(PAYLOAD_TYPE.MESSAGE_GET_TREE, '');
                break;
            case 'focus':
                if (this._active.client.id === id)
                    return;
                // eslint-disable-next-line no-case-declarations
                const current_active = this._clients.get(this._active.client.id);
                if (current_active)
                    current_active.focused = false;
                this._active.client.updateProperty('id', id);
                this._active.client.updateProperty('name', client.name);
                this._active.client.updateProperty('class', client.shell === 'xwayland'
                    ? client.window_properties?.class || ''
                    : client.app_id,
                );
                break;
            case 'title':
                if (client.focused)
                    this._active.client.updateProperty('name', client.name);
                this._clients.set(id, client);
                this.notify('clients');
                break;
            case 'fullscreen_mode':
            case 'urgent':
            case 'mark':
            default:
                this._clients.set(id, client);
                this.notify('clients');
        }
    }

    _handleTreeMessage(node) {
        switch (node.type) {
            case 'root':
                this._workspaces.clear();
                this._clients.clear();
                this._monitors.clear();
                node.nodes.map(n => this._handleTreeMessage(n));
                break;
            case 'output':
                this._monitors.set(node.id, node);
                if (node.active)
                    this._active.monitor.update(node.id, node.name);
                node.nodes.map(n => this._handleTreeMessage(n));
                this.notify('monitors');
                break;
            case 'workspace':
                this._workspaces.set(node.name, node);
                // I think I'm missing something. There has to be a better way.
                // eslint-disable-next-line no-case-declarations
                const hasFocusedChild =
                    (n) => n.nodes.some(c => c.focused || hasFocusedChild(c));
                if (node.focused || hasFocusedChild(node))
                    this._active.workspace.update(node.id, node.name);

                node.nodes.map(n => this._handleTreeMessage(n));
                this.notify('workspaces');
                break;
            case 'con':
            case 'floating_con':
                this._clients.set(node.id, node);
                if (node.focused) {
                    this._active.client.updateProperty('id', node.id);
                    this._active.client.updateProperty('name', node.name);
                    this._active.client.updateProperty('class', node.shell === 'xwayland'
                        ? node.window_properties?.class || ''
                        : node.app_id,
                    );
                }
                node.nodes.map(n => this._handleTreeMessage(n));
                this.notify('clients');
                break;
        }
    }
}

export const sway = new Sway;
export default sway;