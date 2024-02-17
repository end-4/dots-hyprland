import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Soup from 'gi://Soup?version=3.0';
import { fileExists } from './messages.js';

const initMessages =
    [
        { role: "user", parts: [{ text: "You are an assistant on a sidebar of a Wayland Linux desktop. Please always use a casual tone when answering your questions, unless requested otherwise or making writing suggestions. These are the steps you should take to respond to the user's queries:\n1. If it's a writing- or grammar-related question or a sentence in quotation marks, Please point out errors and correct when necessary using underlines, and make the writing more natural where appropriate without making too major changes. If you're given a sentence in quotes but is grammatically correct, explain briefly concepts that are uncommon.\n2. If it's a question about system tasks, give a bash command in a code block with very brief explanation for each command\n3. Otherwise, when asked to summarize information or explaining concepts, you are encouraged to use bullet points and headings. Use casual language and be short and concise. \nThanks!" }], },
        { role: "model", parts: [{ text: "- Got it!" }], },
        { role: "user", parts: [{ text: "\"He rushed to where the event was supposed to be hold, he didn't know it got calceled\"" }], },
        { role: "model", parts: [{ text: "## Grammar correction\nErrors:\n\"He rushed to where the event was supposed to be __hold____,__ he didn't know it got calceled\"\nCorrection + minor improvements:\n\"He rushed to the place where the event was supposed to be __held____, but__ he didn't know that it got calceled\"" }], },
        { role: "user", parts: [{ text: "raise volume by 5%" }], },
        { role: "model", parts: [{ text: "## Volume +5```bash\nwpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+\n```\nThis command uses the `wpctl` utility to adjust the volume of the default sink." }], }, { role: "user", parts: [{ text: "main advantages of the nixos operating system" }], },
        { role: "model", parts: [{ text: "## NixOS advantages\n- **Reproducible**: A config working on one device will also work on another\n- **Declarative**: One config language to rule them all. Effortlessly share them with others.\n- **Reliable**: Per-program software versioning. Mitigates the impact of software breakage" }], },
        { role: "user", parts: [{ text: "whats skeumorphism" }], },
        { role: "model", parts: [{ text: "## Skeuomorphism\n- A design philosophy- From early days of interface designing- Tries to imitate real-life objects- It's in fact still used by Apple in their icons until today." }], },
        { role: "user", parts: [{ text: "\"ignorance is bliss\"" }], },
        { role: "model", parts: [{ text: "## \"Ignorance is bliss\"\n- A Latin proverb that means being unaware of something negative can be a source of happiness\n- Often used to justify avoiding difficult truths or responsibilities\n- Can also be interpreted as a warning against seeking knowledge that may bring pain or sorrow" }], },
    ];

function expandTilde(path) {
    if (path.startsWith('~')) {
        return GLib.get_home_dir() + path.slice(1);
    } else {
        return path;
    }
}

Utils.exec(`mkdir -p ${GLib.get_user_cache_dir()}/ags/user/ai`);
const KEY_FILE_LOCATION = `${GLib.get_user_cache_dir()}/ags/user/ai/google_key.txt`;
const APIDOM_FILE_LOCATION = `${GLib.get_user_cache_dir()}/ags/user/ai/google_api_dom.txt`;
function replaceapidom(URL) {
    if (fileExists(expandTilde(APIDOM_FILE_LOCATION))) {
        var contents = Utils.readFile(expandTilde(APIDOM_FILE_LOCATION)).trim();
        var URL = URL.toString().replace("generativelanguage.googleapis.com", contents);
    }
    return URL;
}
const CHAT_MODELS = ["gemini-pro"]
const ONE_CYCLE_COUNT = 3;

class GeminiMessage extends Service {
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
    _parts = [{ text: '' }];
    _thinking = false;
    _done = false;
    _rawData = '';

    constructor(role, content, thinking = false, done = false) {
        super();
        this._role = role;
        this._parts = [{ text: content }];
        this._thinking = thinking;
        this._done = done;
    }

    get rawData() { return this._rawData }
    set rawData(value) { this._rawData = value }

    get done() { return this._done }
    set done(isDone) { this._done = isDone; this.notify('done') }

    get role() { return this._role }
    set role(role) { this._role = role; this.emit('changed') }

    get content() {
        return this._parts.map(part => part.text).join();
    }
    set content(content) {
        this._parts = [{ text: content }];
        this.notify('content')
        this.emit('changed')
    }

    get parts() { return this._parts }

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

    parseSection() {
        if(this._thinking) {
            this._thinking = false;
            this._parts[0].text= '';
        }
        const parsedData = JSON.parse(this._rawData);
        const delta = parsedData.candidates[0].content.parts[0].text;
        this._parts[0].text += delta;
        // this.emit('delta', delta);
        this.notify('content');
        this._rawData = '';
    }
}

class GeminiService extends Service {
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
                try {
                    const [bytes] = stream.read_line_finish(res);
                    const line = this._decoder.decode(bytes);
                    if (line == '[{') { // beginning of response
                        aiResponse._rawData += '{';
                        this.thinking = false;
                    }
                    else if (line == ',\u000d' || line == ']') { // end of stream pulse
                        aiResponse.parseSection();
                    }
                    else // Normal content
                        aiResponse._rawData += line;

                    this.readResponse(stream, aiResponse);
                } catch {
                    aiResponse.done = true;
                    return;
                }
            });
    }

    addMessage(role, message) {
        this._messages.push(new GeminiMessage(role, message));
        this.emit('newMsg', this._messages.length - 1);
    }

    send(msg) {
        this._messages.push(new GeminiMessage('user', msg));
        this.emit('newMsg', this._messages.length - 1);
        const aiResponse = new GeminiMessage('model', 'thinking...', true, false)

        const body =
        {
            "contents": this._messages.map(msg => { let m = { role: msg.role, parts: msg.parts }; return m; }),
            // "safetySettings": [
            //     { category: "HARM_CATEGORY_DEROGATORY", threshold: "BLOCK_NONE", },
            //     { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE", },
            //     { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE", },
            //     { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE", },
            //     { category: "HARM_CATEGORY_UNSPECIFIED", threshold: "BLOCK_NONE", },
            // ],
            "generationConfig": {
                "temperature": this._temperature,
            },
            // "key": this._key,
            // "apiKey": this._key,
        };

        const session = new Soup.Session();
        const message = new Soup.Message({
            method: 'POST',
            uri: GLib.Uri.parse(replaceapidom(`https://generativelanguage.googleapis.com/v1/models/${this.modelName}:streamGenerateContent?key=${this._key}`), GLib.UriFlags.NONE),
        });
        message.request_headers.append('Content-Type', `application/json`);
        message.set_request_body_from_bytes('application/json', new GLib.Bytes(JSON.stringify(body)));

        session.send_async(message, GLib.DEFAULT_PRIORITY, null, (_, result) => {
            const stream = session.send_finish(result);
            this.readResponse(new Gio.DataInputStream({
                close_base_stream: true,
                base_stream: stream
            }), aiResponse);
        });
        this._messages.push(aiResponse);
        this.emit('newMsg', this._messages.length - 1);

        if (this._cycleModels) {
            this._requestCount++;
            if (this._cycleModels)
                this._modelIndex = (this._requestCount - (this._requestCount % ONE_CYCLE_COUNT)) % CHAT_MODELS.length;
        }
    }
}

export default new GeminiService();

