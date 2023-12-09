import { Utils, Widget } from '../imports.js';
import Service from 'resource:///com/github/Aylur/ags/service.js';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Soup from 'gi://Soup?version=3.0';

const OPENAI_API_KEY = Utils.readFile(`${GLib.get_user_cache_dir()}/ags/user/openai_api_key.txt`).trim();

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
            'newMsg': ['int'],
            'clear': [],
        });
    }

    messages = [];
    _decoder = new TextDecoder();
    url = GLib.Uri.parse('https://api.openai.com/v1/chat/completions', GLib.UriFlags.NONE);

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

    send(msg) {
        this.messages.push(new ChatGPTMessage('user', msg));
        this.emit('newMsg', this.messages.length - 1);
        const aiResponse = new ChatGPTMessage('assistant', 'thinking...', true, false)
        this.messages.push(aiResponse);
        this.emit('newMsg', this.messages.length - 1);

        const body = {
            model: "gpt-3.5-turbo",
            messages: this.messages.map(msg => { let m = { role: msg.role, content: msg.content }; return m; }),
            stream: true,
        };

        const session = new Soup.Session();
        const message = new Soup.Message({
            method: 'POST',
            uri: this.url,
        });
        message.request_headers.append('Authorization', `Bearer ${OPENAI_API_KEY}`);
        message.set_request_body_from_bytes('application/json', new GLib.Bytes(JSON.stringify(body)));

        session.send_async(message, GLib.DEFAULT_PRIORITY, null, (_, result) => {
            const stream = session.send_finish(result);
            this.readResponse(new Gio.DataInputStream({
                close_base_stream: true,
                base_stream: stream
            }), aiResponse);
        });
    }
}

export default new ChatGPTService();













