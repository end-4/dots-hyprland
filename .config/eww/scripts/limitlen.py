#!/bin/python3
import sys

def limit_length(s, newlength):
    # Use len() function to get number of characters in s
    char_count = 0
    newstr = ''
    # Use unicodedata.east_asian_width() function to check for double-width characters
    import unicodedata
    for c in s:
        char_count += 1
        if unicodedata.east_asian_width(c) == 'W':
            char_count += 1
        if char_count <= newlength:
            newstr += c
        else:
            newstr = newstr + '...'
            break
    # Add double-width count to character count to get display length
    return newstr

original = sys.argv[1]
newlen = int(sys.argv[2])
newstr = limit_length(original, newlen)

print(newstr)
