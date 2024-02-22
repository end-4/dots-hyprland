#!/usr/bin/python3
# Import the requests module
import requests
import json
import os
import sys

# Define the URL to send the GET request
url = "https://api.waifu.pics/sfw/waifu"
if len(sys.argv) > 1 and sys.argv[1] == '--segs':
    url = "https://api.waifu.pics/nsfw/"
    if len(sys.argv) > 2:
        url += sys.argv[2]
    else:
        url += "waifu"
else:
    url = "https://api.waifu.pics/sfw/"
    if len(sys.argv) > 1:
        url += sys.argv[1]
    else:
        url += "waifu"

# Send the GET request and store the response object
response = requests.get(url)

# Check if the request was successful
if response.status_code == 200:
    # Print the received data as JSON
    results = response.json()
    link=results['url']
    os.system('wget -O "{0}" "{1}" -q –read-timeout=0.1'.format('eww_covers/waifu_tmp', link))
    os.system('mv ./eww_covers/waifu_tmp ./eww_covers/waifu')
    print('eww_covers/waifu')
else:
    # Print an error message
    print("Something went wrong. Status code:", response.status_code)