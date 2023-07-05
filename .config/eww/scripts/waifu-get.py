#!/usr/bin/python3
import requests
import json
import os
import sys
from PIL import Image

def printhelp():
    print('''
Usage: waifu-get.py [OPTION]... [TAG]...

Options:
    --segs\tForce NSFW images
    --im\tUse waifu.im API. You can use many tags
    --pics\tUse waifu.pics API. Use 1 tag only.
    --nekos\tUse nekos.life (old) API. No tags.

Tags:
    waifu.im (type):
        maid waifu marin-kitagawa mori-calliope raiden-shogun oppai selfies uniform
    waifu.im (nsfw tags):
        ecchi hentai ero ass paizuri oral milf
    ''')
    exit()

###### help ######
if len(sys.argv) == 1:
    printhelp()

###### variables ######
mode = 'im' # either 'im' (waifu.im), 'nekos' (nekos.life), or 'pics' (waifu.pics)
taglist = []
segs = False
output = {}
headers = {}

###### arguments ######
for i in range(1, len(sys.argv)): # Add tags
    if sys.argv[i] == '--segs':
        segs = True
    elif sys.argv[i] == '--im':
        mode = 'im'
    elif sys.argv[i] == '--neko':
        mode = 'nekos'
    elif sys.argv[i] == '--pics':
        mode = 'pics'
    elif sys.argv[i] == '--help' or sys.argv[i] == '-h':
        printhelp()
    else:
        taglist.append(sys.argv[i])

###### prepare request ######
if mode == 'im':
    url = 'https://api.waifu.im/search'
    headers = {'Accept-Version': 'v5'}

elif mode == 'nekos':
    if segs:
        url = 'https://nekos.life/api/lewd/neko'
    else:
        url = 'https://nekos.life/api/neko'

elif mode == 'pics':
    if segs:
        url = 'https://api.waifu.pics/nsfw/'
    else:
        url = 'https://api.waifu.pics/sfw/'

    if len(taglist) > 0:
        url += taglist[0]
    else:
        url += 'waifu'

else: # default: waifu.im
    url = 'https://api.waifu.im/search'
    headers = {'Accept-Version': 'v5'}


params = {
    'included_tags': taglist,
    'height': '>=600'
}
response = requests.get(url, params=params, headers=headers)

# print(response.json())

###### processing ######
if response.status_code == 200:
    data = response.json()
    # Process the response data as needed
    if mode == 'im':
        output['link'] = data['images'][0]['url']
    elif mode == 'nekos':
        output['link'] = data['neko']
    else:
        output['link'] = data['url']

    os.system('wget -O "{0}" "{1}" -q –read-timeout=0.1'.format('eww_covers/waifu_tmp', output['link']))
    os.system('eww update waifu=\'{"name":"eww_covers/waifu_loading", "size": [0, 100]}\'')
    os.system('mv ./eww_covers/waifu_tmp ./eww_covers/waifu')

    with Image.open('./eww_covers/waifu') as img:
        output['size'] = img.size
        output['path'] = 'eww_covers/waifu'
        print(json.dumps(output))

else:
    print('Request failed with status code:', response.status_code)
