import { userOptions } from "../modules/core/configuration/user_options";
import { GObject, register, signal, property } from "astal/gobject"

const APISERVICES = {
    'yandere': {
        name: 'yande.re',
        endpoint: 'https://yande.re/post.json',
    },
    'konachan': {
        name: 'Konachan',
        endpoint: 'https://konachan.net/post.json',
    },
}

const getWorkingImageSauce = (url: string) => {
    if (url.includes('pximg.net')) {
        return `https://www.pixiv.net/en/artworks/${url.substring(url.lastIndexOf('/') + 1).replace(/_p\d+\.(png|jpg|jpeg|gif)$/, '')}`;
    }
    return url;
}

function paramStringFromObj(params: { [s: string]: string; } | ArrayLike<unknown>) {
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

interface IBooruQuery {
    providerName: string;
    taglist: string[];
    realTagList: string[];
    page: number;
}

@register()
class BooruService extends GObject.Object {
    @property(String) declare mode: keyof typeof APISERVICES;
    @property(String) declare nsfw: string;
    @property(String) declare responses: string[];
    @property() declare queries: IBooruQuery[];

    @signal() declare initialized: () => void;
    @signal() clear() {
        this.responses = [];
        this.queries = [];
    }
    @signal(Number) declare newResponse: (id: number) => void;
    @signal(Number) declare updateResponse: (id: number) => void;

    constructor() {
        super();
        this.mode = 'yandere';
        this.nsfw = userOptions.sidebar.image.allowNsfw;
        this.responses = [];
        this.queries = [];
        this.initialized();
    }

    get baseUrl() {
        return APISERVICES[this.mode].endpoint
    }

    get providerName() {
        return APISERVICES[this.mode].name;
    }

    async fetch(msg: string) {
        // Init
        const userArgs = `${msg.replace('rating:safe', '')}${(!this.nsfw || msg.includes('safe')) ? ' rating:safe' : ''}`.split(/\s+/);
        // console.log(userArgs)

        let taglist = [];
        let page = 1;
        // Construct body/headers
        for (let i = 0; i < userArgs.length; i++) {
            const thisArg = userArgs[i].trim();
            if (thisArg.length == 0 || thisArg == '.' || thisArg.includes('*')) continue;
            else if (!isNaN(Number(thisArg))) page = parseInt(thisArg);
            else taglist.push(thisArg);
        }
        const newMessageId = this.queries.length;
        this.queries.push({
            providerName: APISERVICES[this.mode].name,
            taglist: taglist.length == 0 ? ['*', `${page}`] : [...taglist, `${page}`],
            realTagList: taglist,
            page: page,
        });
        this.emit('newResponse', newMessageId);
        const params = {
            'tags': taglist.join('+'),
            'page': `${page}`,
            'limit': `${userOptions.sidebar.image.batchCount}`,
        };
        const paramString = paramStringFromObj(params);
        // Fetch
        // Note: body isn't included since passing directly to url is more reliable
        const options: RequestInit = {
            method: 'GET',
            // headers: APISERVICES[this.mode].headers,
        };
        let status = 0;
        // console.log(`${APISERVICES[this.mode].endpoint}?${paramString}`);

        fetch(`${APISERVICES[this.mode].endpoint}?${paramString}`, options)
            .then(result => {
                status = result.status;
                return result.text();
            })
            .then((dataString) => { // Store interesting stuff and emit
                // console.log(dataString);
                const parsedData = JSON.parse(dataString);
                // console.log(parsedData)
                this.responses[newMessageId] = parsedData.map((obj: { width: number; height: number; id: any; tags: any; rating: string; md5: any; preview_url: any; preview_width: any; preview_height: any; sample_url: any; sample_width: any; sample_height: any; file_url: any; file_ext: any; file_width: any; file_height: any; source: any; }) => {
                    return {
                        aspect_ratio: obj.width / obj.height,
                        id: obj.id,
                        tags: obj.tags,
                        rating: obj.rating,
                        is_nsfw: (obj.rating != 's'),
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
                });
                this.emit('updateResponse', newMessageId);
            })
            .catch(print);

    }
}

export default new BooruService();

