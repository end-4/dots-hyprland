import { Utils, Widget } from '../imports.js';
import Service from 'resource:///com/github/Aylur/ags/service.js';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Soup from 'gi://Soup?version=3.0';
import { fileExists } from './messages.js';

class WaifuResponse extends Service {
    static {
        Service.register(this,
            {
                'delta': ['string'],
            },
            {
                'content': ['string'],
                'thinking': ['boolean'],
                'done': ['boolean'],
            });
    }

    _role = '';
    _content = '';
    _thinking = false;
    _done = false;

    constructor(role, content, thinking = false, done = false) {
        super();
        this._role = role;
        this._content = content;
        this._thinking = thinking;
        this._done = done;
    }

    get done() { return this._done }
    set done(isDone) { this._done = isDone; this.notify('done') }

    get role() { return this._role }
    set role(role) { this._role = role; this.emit('changed') }

    get content() { return this._content }
    set content(content) {
        this._content = content;
        this.notify('content')
        this.emit('changed')
    }

    get label() { return this._parserState.parsed + this._parserState.stack.join('') }

    get thinking() { return this._thinking }
    set thinking(thinking) {
        this._thinking = thinking;
        this.notify('thinking')
        this.emit('changed')
    }

    addDelta(delta) {
        if (this.thinking) {
            this.thinking = false;
            this.content = delta;
        }
        else {
            this.content += delta;
        }
        this.emit('delta', delta);
    }
}

class WaifuService extends Service {
    _endpoints = {
        'im': 'https://api.waifu.im/search',
        'nekos': 'https://nekos.life/api/neko',
        'pics': 'https://api.waifu.pics/sfw/',
    }
    _headers = {
        'im': { 'Accept-Version': 'v5' },
        'nekos': {},
        'pics': {},
    }
    _url = 'https://api.waifu.im/search';
    _mode = 'im'; // Allowed: im
    _responses = [];
    _nsfw = false;
    _minHeight = 600;

    static {
        Service.register(this, {
            'initialized': [],
            'clear': [],
            'newResponse': ['string'],
        });
    }

    constructor() {
        super();
        this.emit('initialized');
    }

    clear() {
        this._responses = [];
        this.emit('clear');
    }

    get mode() { return this._mode }
    set mode(value) {
        this._mode = value;
        this._url = this._endpoints[this._mode];
    }
    get nsfw() { return this._nsfw }
    set nsfw(value) { this._nsfw = value }
    get responses() { return this._responses }

    readResponseRecursive(stream, response) {
        stream.read_line_async(
            0, null,
            (stream, res) => {
                if (!stream) return;
                const [bytes] = stream.read_line_finish(res);
                const line = this._decoder.decode(bytes);
                if (line && line != '') {
                    let data = line.substr(6);
                    if (data == '[DONE]') return;
                    try {
                        const result = JSON.parse(data);
                        if (result.choices[0].finish_reason === 'stop') {
                            response.done = true;
                            return;
                        }
                        response.addDelta(result.choices[0].delta.content);
                    }
                    catch {
                        response.addDelta(line + '\n');
                    }
                }
                this.readResponseRecursive(stream, response);
            });
    }

    fetch(msg) {
        const taglist = msg.split(' ');
        this.emit('newResponse', msg);
        this._responses.push(msg);

        const params = {
            'included_tags': taglist,
            'height': `>=${this._minHeight}`,
            'nsfw': this._nsfw,
        };

        const session = new Soup.Session();
        const message = new Soup.Message({
            method: 'GET',
            uri: GLib.Uri.parse(this._url, GLib.UriFlags.NONE),
        });
        session.send_message(message, (session, message) => {
            if (message.status_code === 200) {
                const responseBody = message.response_body.data;
                const data = JSON.parse(responseBody);
                // Process the response data as needed
                console.log(data);
                log(data);
            } else {
                logError('Request failed with status code: ' + message.status_code);
            }
        });

    }
}

export default new WaifuService();

