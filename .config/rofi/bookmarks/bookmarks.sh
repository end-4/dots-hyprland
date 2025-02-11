#!/bin/bash
#
# Github:
# https://github.com/Strix007/rofi-bookmarks
#
# USAGE ############################################################################################################################################################
#
# - Add Bookmark
#
# To add a bookmark, start the line with + then your url. Default browser is settetd in your envirorment variables ($BROWSER)
# Note: If your bookmark does not contain a domain extension, it will default to .com
#
# - Remove Bookmark
#
# To remove a bookmark, start the line with _ then your url
# Note: It fuzzy matches the input to the saved bookmarks
#
# - Addition Usage
#
# If you type a address that is not saved in your saved bookmarks, it will open the browser with that address
# Note: If the address does not contain a domain extension, it will default to a google search.
#
# - Saved Bookmarks
#
# The bookmarks are saved in a hidden plain text file in $HOME/.scripts/rofi/rofi-webookmarks/bookmarks
# You can manually add bookmarks to $HOME/.scripts/rofi/rofi-webookmarks/bookmarks by starting a new line your bookmark. For Example - youtube.com
# Note: Make sure every bookmark is on a seperate line
#
#################################################################################################################################################################
#
DIR="$HOME/.config/rofi/bookmarks/"
THEME="$HOME/.local/share/rofi/themes/style-4.rasi"
BOOKMARKS_FILE="$HOME/.config/rofi/bookmarks/.bookmarks"
# Note: the default browser is setted by the default envirorment variable $BROWSER
# You can change in uncommenting the following line (the example browser is "firefox")
#BROWSER="firefox"

# Check if there is a bookmarks file and if not, make one

if [[ ! -a "${BOOKMARKS_FILE}" ]]; then
    touch "${BOOKMARKS_FILE}"
fi

INPUT=$(rofi -dmenu -theme ${THEME} -p "" < "$BOOKMARKS_FILE")

if   [[ $INPUT == "+"* ]]; then
    INPUT=$(echo $INPUT | sed 's/+//')
    if [[ $INPUT == *"."* ]]; then
        echo "$INPUT" >> "$BOOKMARKS_FILE"
    else 
        INPUT="${INPUT}.com" && echo "$INPUT" >> "$BOOKMARKS_FILE"
    fi
elif [[ $INPUT == "_"* ]]; then
    INPUT=$(echo "$INPUT" | sed 's/_//') && sed -i "/$INPUT/d" "$BOOKMARKS_FILE"
elif [[ $INPUT == *"."* ]]; then
    $BROWSER "$INPUT"
elif [[ -z $INPUT  ]]; then
    exit 0
else
    xdg-open  "https://www.google.com/search?q=$INPUT"
    # $BROWSER --search $INPUT
    # Set search engine (comment $BROWSER --search $INPUT and uncomment the following (example is duckducgo)
    # $BROWSER "http://www.duckduckgo.com/search?q=$INPUT"
fi
