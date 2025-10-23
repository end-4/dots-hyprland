#!/usr/bin/env bash
grim -g "$(slurp)" /tmp/image.png
imageLink=$(curl -sF files[]=@/tmp/image.png 'https://uguu.se/upload' | jq -r '.files[0].url')
xdg-open "https://lens.google.com/uploadbyurl?url=${imageLink}"
rm /tmp/image.png
