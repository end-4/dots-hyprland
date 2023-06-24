#!/usr/bin/python3

import requests
import json
import os
import sys

NUM_OF_IMAGES = 7
if len(sys.argv) > 1:
    NUM_OF_IMAGES = int(sys.argv[1])

# Define the endpoint URL
url = 'https://api.waifu.pics/many/sfw/waifu'

# Define the request payload
payload = {
    'exclude': [
    ]
}

# Send a POST request to the endpoint
response = requests.post(url, json=payload)

# Parse the response JSON data
response_data = json.loads(response.content)
response_data=response_data['files']


for i, url in enumerate(response_data):
    if i > NUM_OF_IMAGES:
        break
    image_filename = f'eww_covers/gallery{i+1}.jpg'
    with open(image_filename, 'wb') as f:
        response = requests.get(url)
        f.write(response.content)
        print(f'{image_filename} saved successfully') # SILENCE THIS LATER


# WRITE JSON OUTPUT HERE