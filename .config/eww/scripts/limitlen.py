#!/bin/python3
import sys
import unicodedata


def limit_length(string, new_length) -> str:
    """
    Truncate a string to a specified length, adding '...' at the end if necessary.

    :param string: The input string.
    :param new_length: The desired maximum length of the output string.
    :return: The truncated string.
    """
    char_count = 0
    new_string = ''

    for character in string:
        char_count += 1
        if unicodedata.east_asian_width(character) == 'W':
            char_count += 1
        if char_count <= new_length:
            new_string += character
        else:
            new_string += '...'
            break

    return new_string


if __name__ == '__main__':
    original = sys.argv[1]
    new_len = int(sys.argv[2])
    new_str = limit_length(original, new_len)

    print(new_str)
