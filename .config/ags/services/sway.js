"use strict";
var __extends = (this && this.__extends) || (function () {
    var extendStatics = function (d, b) {
        extendStatics = Object.setPrototypeOf ||
            ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
            function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
        return extendStatics(d, b);
    };
    return function (d, b) {
        if (typeof b !== "function" && b !== null)
            throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
var _a, _b, _c, _d;
Object.defineProperty(exports, "__esModule", { value: true });
exports.sway = exports.Sway = exports.SwayActives = exports.SwayActiveID = exports.SwayActiveClient = void 0;
var _1 = require("gi://GLib");
var _2 = require("gi://Gio");
var service_js_1 = require("../service.js");
var SIS = _1.default.getenv('SWAYSOCK');
var SwayActiveClient = /** @class */ (function (_super) {
    __extends(SwayActiveClient, _super);
    function SwayActiveClient() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this._id = 0;
        _this._name = '';
        _this._class = '';
        return _this;
    }
    Object.defineProperty(SwayActiveClient.prototype, "id", {
        get: function () { return this._id; },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SwayActiveClient.prototype, "name", {
        get: function () { return this._name; },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SwayActiveClient.prototype, "class", {
        get: function () { return this._class; },
        enumerable: false,
        configurable: true
    });
    SwayActiveClient.prototype.updateProperty = function (prop, value) {
        _super.prototype.updateProperty.call(this, prop, value);
        this.emit('changed');
    };
    return SwayActiveClient;
}(service_js_1.default));
exports.SwayActiveClient = SwayActiveClient;
_a = SwayActiveClient;
(function () {
    service_js_1.default.register(_a, {}, {
        'id': ['int'],
        'name': ['string'],
        'class': ['string'],
    });
})();
var SwayActiveID = /** @class */ (function (_super) {
    __extends(SwayActiveID, _super);
    function SwayActiveID() {
        var _this = _super !== null && _super.apply(this, arguments) || this;
        _this._id = 1;
        _this._name = '';
        return _this;
    }
    Object.defineProperty(SwayActiveID.prototype, "id", {
        get: function () { return this._id; },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SwayActiveID.prototype, "name", {
        get: function () { return this._name; },
        enumerable: false,
        configurable: true
    });
    SwayActiveID.prototype.update = function (id, name) {
        _super.prototype.updateProperty.call(this, 'id', id);
        _super.prototype.updateProperty.call(this, 'name', name);
        this.emit('changed');
    };
    return SwayActiveID;
}(service_js_1.default));
exports.SwayActiveID = SwayActiveID;
_b = SwayActiveID;
(function () {
    service_js_1.default.register(_b, {}, {
        'id': ['int'],
        'name': ['string'],
    });
})();
var SwayActives = /** @class */ (function (_super) {
    __extends(SwayActives, _super);
    function SwayActives() {
        var _this = _super.call(this) || this;
        _this._client = new SwayActiveClient;
        _this._monitor = new SwayActiveID;
        _this._workspace = new SwayActiveID;
        ['client', 'workspace', 'monitor'].forEach(function (obj) {
            _this["_".concat(obj)].connect('changed', function () {
                _this.notify(obj);
                _this.emit('changed');
            });
        });
        return _this;
    }
    Object.defineProperty(SwayActives.prototype, "client", {
        get: function () { return this._client; },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SwayActives.prototype, "monitor", {
        get: function () { return this._monitor; },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(SwayActives.prototype, "workspace", {
        get: function () { return this._workspace; },
        enumerable: false,
        configurable: true
    });
    return SwayActives;
}(service_js_1.default));
exports.SwayActives = SwayActives;
_c = SwayActives;
(function () {
    service_js_1.default.register(_c, {}, {
        'client': ['jsobject'],
        'monitor': ['jsobject'],
        'workspace': ['jsobject'],
    });
})();
var Sway = /** @class */ (function (_super) {
    __extends(Sway, _super);
    function Sway() {
        var _this = this;
        if (!SIS)
            console.error('Sway is not running');
        _this = _super.call(this) || this;
        _this._decoder = new TextDecoder();
        _this._encoder = new TextEncoder();
        _this._active = new SwayActives();
        _this._monitors = new Map();
        _this._workspaces = new Map();
        _this._clients = new Map();
        var socket = new _2.default.SocketClient().connect(new _2.default.UnixSocketAddress({
            path: "".concat(SIS),
        }), null);
        _this._watchSocket(socket.get_input_stream());
        _this._output_stream = socket.get_output_stream();
        _this.send(4 /* PAYLOAD_TYPE.MESSAGE_GET_TREE */, '');
        _this.send(2 /* PAYLOAD_TYPE.MESSAGE_SUBSCRIBE */, JSON.stringify(['window', 'workspace']));
        _this._active.connect('changed', function () { return _this.emit('changed'); });
        ['monitor', 'workspace', 'client'].forEach(function (active) {
            return _this._active.connect("notify::".concat(active), function () { return _this.notify('active'); });
        });
        return _this;
    }
    Object.defineProperty(Sway.prototype, "active", {
        get: function () { return this._active; },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(Sway.prototype, "monitors", {
        get: function () { return Array.from(this._monitors.values()); },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(Sway.prototype, "workspaces", {
        get: function () { return Array.from(this._workspaces.values()); },
        enumerable: false,
        configurable: true
    });
    Object.defineProperty(Sway.prototype, "clients", {
        get: function () { return Array.from(this._clients.values()); },
        enumerable: false,
        configurable: true
    });
    Sway.prototype.getMonitor = function (id) { return this._monitors.get(id); };
    Sway.prototype.getWorkspace = function (name) { return this._workspaces.get(name); };
    Sway.prototype.getClient = function (id) { return this._clients.get(id); };
    Sway.prototype.send = function (payloadType, payload) {
        var pb = this._encoder.encode(payload);
        var type = new Uint32Array([payloadType]);
        var pl = new Uint32Array([pb.length]);
        var magic_string = this._encoder.encode('i3-ipc');
        var data = new Uint8Array(__spreadArray(__spreadArray(__spreadArray(__spreadArray([], magic_string, true), (new Uint8Array(pl.buffer)), true), (new Uint8Array(type.buffer)), true), pb, true));
        this._output_stream.write(data, null);
    };
    Sway.prototype._watchSocket = function (stream) {
        var _this = this;
        stream.read_bytes_async(14, _1.default.PRIORITY_DEFAULT, null, function (_, resultHeader) {
            var data = stream.read_bytes_finish(resultHeader).get_data();
            if (!data)
                return;
            var payloadLength = new Uint32Array(data.slice(6, 10).buffer)[0];
            var payloadType = new Uint32Array(data.slice(10, 14).buffer)[0];
            stream.read_bytes_async(payloadLength, _1.default.PRIORITY_DEFAULT, null, function (_, resultPayload) {
                var data = stream.read_bytes_finish(resultPayload).get_data();
                if (!data)
                    return;
                _this._onEvent(payloadType, JSON.parse(_this._decoder.decode(data)));
                _this._watchSocket(stream);
            });
        });
    };
    Sway.prototype._onEvent = function (event_type, event) {
        return __awaiter(this, void 0, void 0, function () {
            return __generator(this, function (_e) {
                if (!event)
                    return [2 /*return*/];
                try {
                    switch (event_type) {
                        case 2147483648 /* PAYLOAD_TYPE.EVENT_WORKSPACE */:
                            this._handleWorkspaceEvent(event);
                            break;
                        case 2147483651 /* PAYLOAD_TYPE.EVENT_WINDOW */:
                            this._handleWindowEvent(event);
                            break;
                        case 4 /* PAYLOAD_TYPE.MESSAGE_GET_TREE */:
                            this._handleTreeMessage(event);
                            break;
                        default:
                            break;
                    }
                }
                catch (error) {
                    logError(error);
                }
                this.emit('changed');
                return [2 /*return*/];
            });
        });
    };
    Sway.prototype._handleWorkspaceEvent = function (workspaceEvent) {
        var workspace = workspaceEvent.current;
        switch (workspaceEvent.change) {
            case 'init':
                this._workspaces.set(workspace.name, workspace);
                this.notify('workspaces');
                break;
            case 'empty':
                this._workspaces.delete(workspace.name);
                this.notify('workspaces');
                break;
            case 'focus':
                this._active.workspace.update(workspace.id, workspace.name);
                this._active.monitor.update(1, workspace.output);
                this._workspaces.set(workspace.name, workspace);
                this._workspaces.set(workspaceEvent.old.name, workspaceEvent.old);
                this.notify('workspaces');
                break;
            case 'rename':
                if (this._active.workspace.id === workspace.id)
                    this._active.workspace.updateProperty('name', workspace.name);
                this._workspaces.set(workspace.name, workspace);
                this.notify('workspaces');
                break;
            case 'reload':
                break;
            case 'move':
            case 'urgent':
            default:
                this._workspaces.set(workspace.name, workspace);
                this.notify('workspaces');
        }
    };
    Sway.prototype._handleWindowEvent = function (clientEvent) {
        var _e;
        var client = clientEvent.container;
        var id = client.id;
        switch (clientEvent.change) {
            case 'new':
                this._clients.set(id, client);
                this.notify('clients');
                break;
            case 'close':
                this._clients.delete(id);
                this.notify('clients');
                break;
            case 'focus':
                if (this._active.client.id === id)
                    return;
                // eslint-disable-next-line no-case-declarations
                var current_active = this._clients.get(this._active.client.id);
                if (current_active)
                    current_active.focused = false;
                this._active.client.updateProperty('id', id);
                this._active.client.updateProperty('name', client.name);
                this._active.client.updateProperty('class', client.shell === 'xwayland'
                    ? ((_e = client.window_properties) === null || _e === void 0 ? void 0 : _e.class) || ''
                    : client.app_id);
                break;
            case 'title':
                if (client.focused)
                    this._active.client.updateProperty('name', client.name);
                this._clients.set(id, client);
                this.notify('clients');
                break;
            case 'fullscreen_mode':
            case 'move':
            case 'floating':
            case 'urgent':
            case 'mark':
            default:
                this._clients.set(id, client);
                this.notify('clients');
        }
    };
    Sway.prototype._handleTreeMessage = function (node) {
        var _this = this;
        var _e;
        switch (node.type) {
            case 'root':
                this._workspaces.clear();
                this._clients.clear();
                this._monitors.clear();
                node.nodes.map(function (n) { return _this._handleTreeMessage(n); });
                ['workspaces', 'clients', 'monitors'].forEach(function (t) {
                    _this.notify(t);
                });
                break;
            case 'output':
                this._monitors.set(node.id, node);
                if (node.active)
                    this._active.monitor.updateProperty('name', node.name);
                node.nodes.map(function (n) { return _this._handleTreeMessage(n); });
                this.notify('monitors');
                break;
            case 'workspace':
                this._workspaces.set(node.name, node);
                // I think I'm missing something. There has to be a better way.
                // eslint-disable-next-line no-case-declarations
                var hasFocusedChild_1 = function (n) { return n.nodes.some(function (c) { return c.focused || hasFocusedChild_1(c); }); };
                if (hasFocusedChild_1(node))
                    this._active.workspace.update(node.id, node.name);
                node.nodes.map(function (n) { return _this._handleTreeMessage(n); });
                this.notify('workspaces');
                break;
            case 'con':
            case 'floating_con':
                this._clients.set(node.id, node);
                if (node.focused) {
                    this._active.client.updateProperty('id', node.id);
                    this._active.client.updateProperty('name', node.name);
                    this._active.client.updateProperty('class', node.shell === 'xwayland'
                        ? ((_e = node.window_properties) === null || _e === void 0 ? void 0 : _e.class) || ''
                        : node.app_id);
                }
                node.nodes.map(function (n) { return _this._handleTreeMessage(n); });
                this.notify('clients');
                break;
        }
    };
    return Sway;
}(service_js_1.default));
exports.Sway = Sway;
_d = Sway;
(function () {
    service_js_1.default.register(_d, {}, {
        'active': ['jsobject'],
        'monitors': ['jsobject'],
        'workspaces': ['jsobject'],
        'clients': ['jsobject'],
    });
})();
exports.sway = new Sway;
exports.default = exports.sway;
