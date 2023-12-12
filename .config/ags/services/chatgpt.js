import { Utils, Widget } from '../imports.js';
import Service from 'resource:///com/github/Aylur/ags/service.js';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Soup from 'gi://Soup?version=3.0';
import { fileExists } from './messages.js';

function expandTilde(path) {
    if (path.startsWith('~')) {
        return GLib.get_home_dir() + path.slice(1);
    } else {
        return path;
    }
}

// We're using many models to not be restricted to 3 messages per minute.
// The whole chat will be sent every request anyway.
const KEY_FILE_LOCATION = `~/.cache/ags/user/openai_api_key.txt`;
const CHAT_MODELS = ["gpt-3.5-turbo", "gpt-3.5-turbo-0613"]
const ONE_CYCLE_COUNT = 3;

class ChatGPTMessage extends Service {
    static {
        Service.register(this, {},
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
    }
}

class ChatGPTService extends Service {
    static {
        Service.register(this, {
            'initialized': [],
            'clear': [],
            'newMsg': ['int'],
            'hasKey': ['boolean'],
            'cycleModels': ['boolean'],
        });
    }

    messages = [];
    _cycleModels = true;
    _thisMinuteCount = 0;
    _modelIndex = 0;
    _key = '';
    _decoder = new TextDecoder();
    url = GLib.Uri.parse('https://api.openai.com/v1/chat/completions', GLib.UriFlags.NONE);

    constructor() {
        super();
        if (fileExists(expandTilde(KEY_FILE_LOCATION))) {
            this._key = Utils.readFile(expandTilde(KEY_FILE_LOCATION)).trim();
        }
        else {
            this.emit('hasKey', false);
        }
        this.emit('initialized');
    }

    get keyPath() { return KEY_FILE_LOCATION }
    get key() { return this._key }
    set key(keyValue) {
        this._key = keyValue;
        Utils.writeFile(this._key, expandTilde(KEY_FILE_LOCATION))
            .then(this.emit('hasKey', true))
            .catch(err => print(err));
    }

    get cycleModels() { return this._cycleModels }
    set cycleModels(value) {
        this._cycleModels = value;
        this.emit('cycleModels', value);
    }

    get messages() { return this.messages }
    get lastMessage() { return this.messages[this.messages.length - 1] }

    clear() {
        this.messages = []
        this.emit('clear');
    }

    readResponse(stream, aiResponse) {
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
                            aiResponse.done = true;
                            return;
                        }
                        aiResponse.addDelta(result.choices[0].delta.content);
                    }
                    catch {
                        aiResponse.addDelta(line + '\n');
                    }
                }
                this.readResponse(stream, aiResponse);
            });
    }

    addMessage(role, message) {
        this.messages.push(new ChatGPTMessage(role, message));
        this.emit('newMsg', this.messages.length - 1);
    }

    send(msg) {
        this.messages.push(new ChatGPTMessage('user', msg));
        this.emit('newMsg', this.messages.length - 1);
        const aiResponse = new ChatGPTMessage('assistant', 'thinking...', true, false)
        this.messages.push(aiResponse);
        this.emit('newMsg', this.messages.length - 1);

        const body = {
            model: CHAT_MODELS[this._modelIndex],
            messages: this.messages.map(msg => { let m = { role: msg.role, content: msg.content }; return m; }),
            stream: true,
        };
        console.log('using model', body.model);

        const session = new Soup.Session();
        const message = new Soup.Message({
            method: 'POST',
            uri: this.url,
        });
        message.request_headers.append('Authorization', `Bearer ${this._key}`);
        message.set_request_body_from_bytes('application/json', new GLib.Bytes(JSON.stringify(body)));

        session.send_async(message, GLib.DEFAULT_PRIORITY, null, (_, result) => {
            const stream = session.send_finish(result);
            this.readResponse(new Gio.DataInputStream({
                close_base_stream: true,
                base_stream: stream
            }), aiResponse);
        });

        if (this._cycleModels) {
            this._thisMinuteCount++;
            this._modelIndex = (this._thisMinuteCount - (this._thisMinuteCount % ONE_CYCLE_COUNT)) % CHAT_MODELS.length;
            console.log(this._modelIndex);
        }

    }
}

export default new ChatGPTService();













