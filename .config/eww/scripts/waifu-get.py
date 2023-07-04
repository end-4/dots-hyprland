#!/usr/bin/python3
import requests
import json
import os
import sys
from PIL import Image

###### variables ######
taglist = []
segs = False

###### arguments ######
for i in range(1, len(sys.argv)): # Add tags
    if sys.argv[i] == '--segs':
        segs = True
    else:
        taglist.append(sys.argv[i])

###### request ######
url = 'https://api.waifu.im/search'
headers = {'Accept-Version': 'v5'}
params = {
    'included_tags': taglist,
    'height': '>=600'
}
response = requests.get(url, params=params, headers=headers)

###### processing ######

if response.status_code == 200:
    data = response.json()
    # Process the response data as needed
    # print(json.dumps(data))
    link=data['images'][0]['url']
    os.system('wget -O "{0}" "{1}" -q –read-timeout=0.1'.format('eww_covers/waifu_tmp', link))
    os.system('eww update waifu=\'{"name":"eww_covers/waifu_loading", "size": [0, 100]}\'')
    os.system('mv ./eww_covers/waifu_tmp ./eww_covers/waifu')

    with Image.open('./eww_covers/waifu') as img:
        width, height = img.size
        print('{' + '"name": "{0}", "size": [{1}, {2}]'.format('eww_covers/waifu', width, height) + '}')

else:
    print('Request failed with status code:', response.status_code)
