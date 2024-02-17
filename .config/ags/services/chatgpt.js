import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Soup from 'gi://Soup?version=3.0';
import { fileExists } from './messages.js';

// Custom prompt
const initMessages =
    [
        { role: "user", content: "You are an assistant on a sidebar of a Wayland Linux desktop. Please always use a casual tone when answering your questions, unless requested otherwise or making writing suggestions. These are the steps you should take to respond to the user's queries:\n1. If it's a writing- or grammar-related question or a sentence in quotation marks, Please point out errors and correct when necessary using underlines, and make the writing more natural where appropriate without making too major changes. If you're given a sentence in quotes but is grammatically correct, explain briefly concepts that are uncommon.\n2. If it's a question about system tasks, give a bash command in a code block with very brief explanation for each command\n3. Otherwise, when asked to summarize information or explaining concepts, you are encouraged to use bullet points and headings. Use casual language and be short and concise. \nThanks!", },
        { role: "assistant", content: "- Got it!", },
        { role: "user", content: "\"He rushed to where the event was supposed to be hold, he didn't know it got calceled\"", },
        { role: "assistant", content: "## Grammar correction\nErrors:\n\"He rushed to where the event was supposed to be __hold____,__ he didn't know it got calceled\"\nCorrection + minor improvements:\n\"He rushed to the place where the event was supposed to be __held____, but__ he didn't know that it got calceled\"", },
        { role: "user", content: "raise volume by 5%", },
        { role: "assistant", content: "## Volume +5```bash\nwpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+\n```\nThis command uses the `wpctl` utility to adjust the volume of the default sink.", },
        { role: "user", content: "main advantages of the nixos operating system", },
        { role: "assistant", content: "## NixOS advantages\n- **Reproducible**: A config working on one device will also work on another\n- **Declarative**: One config language to rule them all. Effortlessly share them with others.\n- **Reliable**: Per-program software versioning. Mitigates the impact of software breakage", },
        { role: "user", content: "whats skeumorphism", },
        { role: "assistant", content: "## Skeuomorphism\n- A design philosophy- From early days of interface designing- Tries to imitate real-life objects- It's in fact still used by Apple in their icons until today.", },
    ];

function expandTilde(path) {
    if (path.startsWith('~')) {
        return GLib.get_home_dir() + path.slice(1);
    } else {
        return path;
    }
}

// We're using many models to not be restricted to 3 messages per minute.
// The whole chat will be sent every request anyway.
Utils.exec(`mkdir -p ${GLib.get_user_cache_dir()}/ags/user/ai`);
const KEY_FILE_LOCATION = `${GLib.get_user_cache_dir()}/ags/user/ai/openai_key.txt`;
const APIDOM_FILE_LOCATION = `${GLib.get_user_cache_dir()}/ags/user/openai_api_dom.txt`;
function replaceapidom(URL) {
    //Utils.writeFile(URL, "/tmp/openai-url-old.log"); // For debugging
    if (fileExists(expandTilde(APIDOM_FILE_LOCATION))) {
        var contents = Utils.readFile(expandTilde(APIDOM_FILE_LOCATION)).trim();
        var URL = URL.toString().replace("api.openai.com", contents);
    }
    //Utils.writeFile(URL, "/tmp/openai-url.log"); // For debugging
    return URL;
}
const CHAT_MODELS = ["gpt-3.5-turbo-1106", "gpt-3.5-turbo", "gpt-3.5-turbo-16k", "gpt-3.5-turbo-0613"]
const ONE_CYCLE_COUNT = 3;

class ChatGPTMessage extends Service {
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

class ChatGPTService extends Service {
    static {
        Service.register(this, {
            'initialized': [],
            'clear': [],
            'newMsg': ['int'],
            'hasKey': ['boolean'],
        });
    }

    _assistantPrompt = true;
    _messages = [];
    _cycleModels = true;
    _requestCount = 0;
    _temperature = 0.9;
    _modelIndex = 0;
    _key = '';
    _decoder = new TextDecoder();

    url = GLib.Uri.parse(replaceapidom('https://api.openai.com/v1/chat/completions'), GLib.UriFlags.NONE);

    constructor() {
        super();

        if (fileExists(expandTilde(KEY_FILE_LOCATION))) this._key = Utils.readFile(expandTilde(KEY_FILE_LOCATION)).trim();
        else this.emit('hasKey', false);

        if (this._assistantPrompt) this._messages = [...initMessages];
        else this._messages = [];

        this.emit('initialized');
    }

    get modelName() { return CHAT_MODELS[this._modelIndex] }

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
        if (!value) this._modelIndex = 0;
        else {
            this._modelIndex = (this._requestCount - (this._requestCount % ONE_CYCLE_COUNT)) % CHAT_MODELS.length;
        }
    }

    get temperature() { return this._temperature }
    set temperature(value) { this._temperature = value; }

    get messages() { return this._messages }
    get lastMessage() { return this._messages[this._messages.length - 1] }

    clear() {
        if (this._assistantPrompt)
            this._messages = [...initMessages];
        else
            this._messages = [];
        this.emit('clear');
    }

    get assistantPrompt() { return this._assistantPrompt; }
    set assistantPrompt(value) {
        this._assistantPrompt = value;
        if (value) this._messages = [...initMessages];
        else this._messages = [];
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
        this._messages.push(new ChatGPTMessage(role, message));
        this.emit('newMsg', this._messages.length - 1);
    }

    send(msg) {
        this._messages.push(new ChatGPTMessage('user', msg));
        this.emit('newMsg', this._messages.length - 1);
        const aiResponse = new ChatGPTMessage('assistant', 'thinking...', true, false)
        this._messages.push(aiResponse);
        this.emit('newMsg', this._messages.length - 1);

        const body = {
            model: CHAT_MODELS[this._modelIndex],
            messages: this._messages.map(msg => { let m = { role: msg.role, content: msg.content }; return m; }),
            temperature: this._temperature,
            // temperature: 2, // <- Nuts
            stream: true,
        };

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
            this._requestCount++;
            if (this._cycleModels)
                this._modelIndex = (this._requestCount - (this._requestCount % ONE_CYCLE_COUNT)) % CHAT_MODELS.length;
        }
    }
}

export default new ChatGPTService();













