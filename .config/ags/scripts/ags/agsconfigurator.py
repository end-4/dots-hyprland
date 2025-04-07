#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
import argparse
import json
import sys
import ast
import re

def parse_value(value):
    """Parse the value into its appropriate Python type (e.g., bool, int, float, list, dict, or string)."""
    try:
        return json.loads(value)
    except json.JSONDecodeError: # Fallback to string if parsing fails
        return value

def remove_trailing_commas(json_string):
    """Remove trailing commas from JSON-like structures."""
    return re.sub(r',\s*([\}\]])', r'\1', json_string)

def strip_comments_except_leading(lines):
    """
    Removes all `//` and `/* ... */` comments, except for leading `//` comments at the start.
    Ensures `//` inside strings is preserved.
    Returns (preserved_comments, cleaned_json).
    """
    preserved_comments = []
    json_lines = []
    in_block_comment = False
    in_string = False
    escaped = False

    for line in lines:
        stripped = line.strip()

        # Handle block comments
        if in_block_comment:
            if "*/" in stripped:
                in_block_comment = False
            continue
        if stripped.startswith("/*"):
            in_block_comment = True
            continue

        # Preserve leading `//` comments at the very start
        if stripped.startswith("//") and not json_lines:
            preserved_comments.append(line)
            continue

        # Process line while tracking if inside a string
        new_line = []
        i = 0
        while i < len(line):
            char = line[i]

            if char == '"' or char == "'":  # Detect string start
                if not in_string:
                    in_string = char
                elif in_string == char and not escaped:
                    in_string = False
            elif char == "\\" and in_string:  # Handle escape sequences
                escaped = not escaped
            else:
                escaped = False

            # Remove inline `//` comments only if not inside a string
            if char == "/" and i + 1 < len(line) and line[i + 1] == "/" and not in_string:
                break  # Stop processing the line at `//` (comment start)

            new_line.append(char)
            i += 1

        cleaned_line = "".join(new_line).rstrip()
        if cleaned_line:
            json_lines.append(cleaned_line + "\n")

    return preserved_comments, json_lines

def update_json(file_path, key, value=None, reset=False):
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()

        # Separate leading comments and clean JSON
        preserved_comments, json_lines = strip_comments_except_leading(lines)
        json_string = "".join(json_lines)
        json_string = remove_trailing_commas(json_string)

        # Convert the cleaned string into a JSON object
        try:
            json_data = json.loads(json_string)
        except json.JSONDecodeError:
            print(f"Error decoding JSON in file: {file_path}")
            sys.exit(1)

        # Navigate through the key (e.g., 'search.enableFeatures.actions')
        keys = key.split('.')
        data = json_data
        for k in keys[:-1]:
            data = data.setdefault(k, {})

        # Update or delete the key
        if reset:
            if keys[-1] in data:
                del data[keys[-1]]
                print(f"Successfully removed {key} from {file_path}")
            else:
                print(f"Key {key} not found in {file_path}")
        else:
            data[keys[-1]] = value
            print(f"Successfully updated {key} to {value} in {file_path}")

        # Write back only valid JSON (with preserved leading comments)
        with open(file_path, 'w') as file:
            file.writelines(preserved_comments)  # Restore leading comments
            json.dump(json_data, file, indent=4)
            file.write("\n")  # Ensure a newline at the end

    except FileNotFoundError:
        print(f"File not found: {file_path}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Update or remove a key from a JSON configuration file")
    parser.add_argument('--key', required=True, help="The key to be updated or removed (e.g., 'search.enableFeatures.actions')")
    parser.add_argument('--file', required=True, help="The path to the target JSON file")
    parser.add_argument('--value', help="The new value to assign (e.g., 'true', '42', '[1, 2, 3]')")
    parser.add_argument('--reset', action='store_true', help="If set, the key will be removed from the JSON file")

    args = parser.parse_args()

    value = None
    if args.value:
        value = parse_value(args.value)

    update_json(args.file, args.key, value, reset=args.reset)
