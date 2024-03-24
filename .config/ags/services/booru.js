import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

const APISERVICES = {
    'yandere': {
        endpoint: 'https://yande.re/post.json',
    }
}

const getWorkingImageSauce = (url) => {
    if (url.includes('pximg.net')) {
        return `https://www.pixiv.net/en/artworks/${url.substring(url.lastIndexOf('/')).replace(/_p\d+\.png$/, '')}`;
    }
    return url;
}

function paramStringFromObj(params) {
    return Object.entries(params)
        .map(([key, value]) => {
            if (Array.isArray(value)) { // If it's an array, repeat
                if (value.length == 0) return '';
                let thisKey = `${encodeURIComponent(key)}=${encodeURIComponent(value[0])}`
                for (let i = 1; i < value.length; i++) {
                    thisKey += `&${encodeURIComponent(key)}=${encodeURIComponent(value[i])}`;
                }
                return thisKey;
            }
            return `${key}=${value}`;
        })
        .join('&');
}

class BooruService extends Service {
    _baseUrl = 'https://yande.re/post.json';
    _mode = 'yandere';
    _nsfw = userOptions.sidebar.imageAllowNsfw;
    _responses = [];
    _queries = [];

    static {
        Service.register(this, {
            'initialized': [],
            'clear': [],
            'newResponse': ['int'],
            'updateResponse': ['int'],
        });
    }

    constructor() {
        super();
        this.emit('initialized');
    }

    clear() {
        this._responses = [];
        this._queries = [];
        this.emit('clear');
    }

    get nsfw() { return this._nsfw }
    set nsfw(value) { this._nsfw = value; }

    get mode() { return this._mode }
    set mode(value) {
        this._mode = value;
        this._baseUrl = APISERVICES[this._mode].endpoint;
    }
    get queries() { return this._queries }
    get responses() { return this._responses }

    async fetch(msg) {
        // Init
        const userArgs = `${msg}${this._nsfw ? '' : ' rating:safe'}`.split(/\s+/);

        let taglist = [];
        // Construct body/headers
        for (let i = 0; i < userArgs.length; i++) {
            const thisArg = userArgs[i].trim();
            if (thisArg.length == 0 || thisArg == '.' || thisArg == '*') continue;
            else taglist.push(thisArg);
        }
        const newMessageId = this._queries.length;
        this._queries.push(taglist.length == 0 ? ['*'] : taglist);
        this.emit('newResponse', newMessageId);
        const params = {
            'tags': taglist.join('+'),
        };
        const paramString = paramStringFromObj(params);
        // Fetch
        // Note: body isn't included since passing directly to url is more reliable
        const options = {
            method: 'GET',
            headers: APISERVICES[this._mode].headers,
        };
        let status = 0;
        Utils.fetch(`${APISERVICES[this._mode].endpoint}?${paramString}`, options)
            .then(result => {
                status = result.status;
                return result.text();
            })
            .then((dataString) => { // Store interesting stuff and emit
                const parsedData = JSON.parse(dataString);
                // console.log(parsedData)
                this._responses.push(parsedData.map(obj => {
                    return {
                        id: obj.id,
                        tags: obj.tags,
                        md5: obj.md5,
                        preview_url: obj.preview_url,
                        preview_width: obj.preview_width,
                        preview_height: obj.preview_height,
                        sample_url: obj.sample_url,
                        sample_width: obj.sample_width,
                        sample_height: obj.sample_height,
                        file_url: obj.file_url,
                        file_ext: obj.file_ext,
                        file_width: obj.file_width,
                        file_height: obj.file_height,
                        source: getWorkingImageSauce(obj.source),
                    }
                }));
                this.emit('updateResponse', newMessageId);
            })
            .catch(print);

    }
}

export default new BooruService();

