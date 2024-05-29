import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Soup from 'gi://Soup?version=3.0';
import { fileExists } from '../modules/.miscutils/files.js';

const PROVIDERS = { // There's this list hmm https://github.com/zukixa/cool-ai-stuff/
    'openai': {
        'name': 'OpenAI',
        'logo_name': 'openai-symbolic',
        'description': 'Official OpenAI API.\nPricing: Free for the first $5 or 3 months, whichever is less.',
        'base_url': 'https://api.openai.com/v1/chat/completions',
        'key_get_url': 'https://platform.openai.com/api-keys',
        'key_file': 'openai_key.txt',
        'model': 'gpt-3.5-turbo',
    },
    'ollama': {
        'name': 'Ollama',
        'logo_name': 'ollama-symbolic',
        'description': 'Official Ollama API.\nPricing: Free.',
        'base_url': 'http://localhost:11434/v1/chat/completions',
        'key_get_url': 'it\'s just ollama',
        'key_file': 'ollama_key.txt',
        'model': 'llama3:instruct',
    },
    'oxygen4o': {
        'name': 'Oxygen (GPT-4o)',
        'logo_name': 'ai-oxygen-symbolic',
        'description': 'An API from Tornado Softwares\nPricing: Free: 100/day\nRequires you to join their Discord for a key',
        'base_url': 'https://app.oxyapi.uk/v1/chat/completions',
        'key_get_url': 'https://discord.com/invite/kM6MaCqGKA',
        'key_file': 'oxygen_key.txt',
        'model': 'gpt-4o',
    },
    'oxygen3': {
        'name': 'Oxygen (GPT-3.5)',
        'logo_name': 'ai-oxygen-symbolic',
        'description': 'An API from Tornado Softwares\nPricing: Free: 100/day\nRequires you to join their Discord for a key',
        'base_url': 'https://app.oxyapi.uk/v1/chat/completions',
        'key_get_url': 'https://discord.com/invite/kM6MaCqGKA',
        'key_file': 'oxygen_key.txt',
        'model': 'gpt-3.5-turbo',
    },
    'zukijourney': {
        'name': 'zukijourney',
        'logo_name': 'ai-zukijourney',
        'description': 'An API from @zukixa on GitHub.\nNote: Keys are IP-locked so it\'s buggy sometimes\nPricing: Free: 10/min, 800/day.\nRequires you to join their Discord for a key',
        'base_url': 'https://zukijourney.xyzbot.net/v1/chat/completions',
        'key_get_url': 'https://discord.com/invite/Y4J6XXnmQ6',
        'key_file': 'zuki_key.txt',
        'model': 'gpt-3.5-turbo',
    },
}

// Custom prompt
const initMessages =
    [
        { role: "user", content: "You are an assistant on a sidebar of a Wayland Linux desktop. Please always use a casual tone when answering your questions, unless requested otherwise or making writing suggestions. These are the steps you should take to respond to the user's queries:\n1. If it's a writing- or grammar-related question or a sentence in quotation marks, Please point out errors and correct when necessary using underlines, and make the writing more natural where appropriate without making too major changes. If you're given a sentence in quotes but is grammatically correct, explain briefly concepts that are uncommon.\n2. If it's a question about system tasks, give a bash command in a code block with brief explanation.\n3. Otherwise, when asked to summarize information or explaining concepts, you are should use bullet points and headings. For mathematics expressions, you *have to* use LaTeX within a code block with the language set as \"latex\". \nNote: Use casual language, be short, while ensuring the factual correctness of your response. If you are unsure or don’t have enough information to provide a confident answer, simply say “I don’t know” or “I’m not sure.”. \nThanks!", },
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

Utils.exec(`mkdir -p ${GLib.get_user_state_dir()}/ags/user/ai`);

class GPTMessage extends Service {
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
    _thinking;
    _done = false;

    constructor(role, content, thinking = true, done = false) {
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
    set thinking(value) {
        this._thinking = value;
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

class GPTService extends Service {
    static {
        Service.register(this, {
            'initialized': [],
            'clear': [],
            'newMsg': ['int'],
            'hasKey': ['boolean'],
            'providerChanged': [],
        });
    }

    _assistantPrompt = true;
    _currentProvider = userOptions.ai.defaultGPTProvider;
    _requestCount = 0;
    _temperature = userOptions.ai.defaultTemperature;
    _messages = [];
    _key = '';
    _key_file_location = `${GLib.get_user_state_dir()}/ags/user/ai/${PROVIDERS[this._currentProvider]['key_file']}`;
    _url = GLib.Uri.parse(PROVIDERS[this._currentProvider]['base_url'], GLib.UriFlags.NONE);

    _decoder = new TextDecoder();

    _initChecks() {
        this._key_file_location = `${GLib.get_user_state_dir()}/ags/user/ai/${PROVIDERS[this._currentProvider]['key_file']}`;
        if (fileExists(this._key_file_location)) this._key = Utils.readFile(this._key_file_location).trim();
        else this.emit('hasKey', false);
        this._url = GLib.Uri.parse(PROVIDERS[this._currentProvider]['base_url'], GLib.UriFlags.NONE);
    }

    constructor() {
        super();
        this._initChecks();

        if (this._assistantPrompt) this._messages = [...initMessages];
        else this._messages = [];

        this.emit('initialized');
    }

    get modelName() { return PROVIDERS[this._currentProvider]['model'] }
    get getKeyUrl() { return PROVIDERS[this._currentProvider]['key_get_url'] }
    get providerID() { return this._currentProvider }
    set providerID(value) {
        this._currentProvider = value;
        this.emit('providerChanged');
        this._initChecks();
    }
    get providers() { return PROVIDERS }

    get keyPath() { return this._key_file_location }
    get key() { return this._key }
    set key(keyValue) {
        this._key = keyValue;
        Utils.writeFile(this._key, this._key_file_location)
            .then(this.emit('hasKey', true))
            .catch(print);
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
        aiResponse.thinking = false;
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
                        // print(result.choices[0])
                    }
                    catch {
                        aiResponse.addDelta(line + '\n');
                    }
                }
                this.readResponse(stream, aiResponse);
            });
    }

    addMessage(role, message) {
        this._messages.push(new GPTMessage(role, message));
        this.emit('newMsg', this._messages.length - 1);
    }

    send(msg) {
        this._messages.push(new GPTMessage('user', msg, false, true));
        this.emit('newMsg', this._messages.length - 1);
        const aiResponse = new GPTMessage('assistant', '', true, false)

        const body = {
            model: PROVIDERS[this._currentProvider]['model'],
            messages: this._messages.map(msg => { let m = { role: msg.role, content: msg.content }; return m; }),
            temperature: this._temperature,
            // temperature: 2, // <- Nuts
            stream: true,
        };
        const proxyResolver = new Gio.SimpleProxyResolver({ 'default-proxy': userOptions.ai.proxyUrl });
        const session = new Soup.Session({ 'proxy-resolver': proxyResolver });
        const message = new Soup.Message({
            method: 'POST',
            uri: this._url,
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
        this._messages.push(aiResponse);
        this.emit('newMsg', this._messages.length - 1);
    }
}

export default new GPTService();













