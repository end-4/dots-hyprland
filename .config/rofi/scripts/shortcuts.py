#!/usr/bin/env python3

import vdf
import sys
import os
import glob
import requests
import shutil

# API key and Base URL for SteamGridDB
STATE_DIR = os.path.expanduser("~/.local/state")
APP_ID_FILE = os.path.join(STATE_DIR, "steamid")
BASE_URL = "https://www.steamgriddb.com/api/v2"

# Check if running in a terminal
def is_running_in_terminal():
    return os.isatty(sys.stdin.fileno())

# Load API key from file
def load_api_key():
    if os.path.exists(APP_ID_FILE):
        with open(APP_ID_FILE, 'r') as f:
            for line in f:
                if line.startswith("API_KEY="):
                    return line.split("=", 1)[1].strip()
    return None

# Save API key to file
def save_api_key(api_key):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(APP_ID_FILE, 'a') as f:
        f.write(f"API_KEY={api_key}\n")

# Load processed app IDs from file
def load_processed_app_ids():
    if os.path.exists(APP_ID_FILE):
        with open(APP_ID_FILE, 'r') as f:
            return {int(line.strip()) for line in f if line.isdigit()}
    return set()

# Save processed app IDs to file
def save_processed_app_ids(app_ids):
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(APP_ID_FILE, 'a') as f:
        for app_id in app_ids:
            f.write(f"{app_id}\n")

# Get API key, either from file or by prompting the user
def get_api_key():
    api_key = load_api_key()
    if not api_key:
        if is_running_in_terminal():
            print("Please create an API key for SteamGridDB by following these steps:")
            print("1. Visit https://www.steamgriddb.com/")
            print("2. Log in or sign up for an account.")
            print("3. Go to 'Account' -> 'API' to create a new API key.")
            api_key = input("Please enter your SteamGridDB API key: ").strip()
            if api_key:
                save_api_key(api_key)
            else:
                print("No API key provided. Exiting...")
                sys.exit(1)
        else:
            notification_message = "No API key found. to add non steam games on the games list please run /rofi/script/shortcuts.py in a terminal to provide the API key."
            print(notification_message)
            os.system(f'notify-send "SteamGridDB" "{notification_message}"')
            sys.exit(1)
    return api_key

# Check if any games are available
def check_games_available(file_path):
    if not os.path.exists(file_path):
        print("No games available. Exiting...")
        sys.exit(0)

# Main script logic
def main():
    API_KEY = get_api_key()

    def find_shortcuts_vdf():
        steam_root = os.path.expanduser("~/.local/share/Steam")
        pattern = os.path.join(steam_root, "userdata/*/config/shortcuts.vdf")
        files = glob.glob(pattern)
        if files:
            return files[0]
        else:
            sys.exit("Error: No shortcuts.vdf file found")

    def search_images_by_name(name):
        headers = {
            "Authorization": f"Bearer {API_KEY}"
        }
        url = f"{BASE_URL}/search/autocomplete/{name}"
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()["data"]
            if data:
                return data[0]["id"]
        return None

    def fetch_image(app_id, image_type):
        headers = {
            "Authorization": f"Bearer {API_KEY}"
        }
        url = f"{BASE_URL}/{image_type}/game/{app_id}"
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()["data"]
            if data:
                return data[0]["url"]
        return None

    def download_image(url, dest_path):
        response = requests.get(url, stream=True)
        if response.status_code == 200:
            with open(dest_path, 'wb') as f:
                for chunk in response.iter_content(1024):
                    f.write(chunk)
            return True
        return False

    def create_library_cache(app_id, original_app_id, name, exe):
        steam_root = os.path.expanduser("~/.local/share/Steam")
        cache_dir = os.path.join(steam_root, f"appcache/librarycache/{original_app_id}")  # Use original app_id
        os.makedirs(cache_dir, exist_ok=True)
        
        image_types = {
            "grids": "library_600x900.jpg",
            "heroes": "library_hero.jpg",
            "logos": "logo.png"  # Keeping the default name for logos
        }
        
        for image_type, file_name in image_types.items():
            image_url = fetch_image(app_id, image_type)
            if image_url:
                dest_path = os.path.join(cache_dir, file_name)
                if download_image(image_url, dest_path):
                    print(f"{image_type.capitalize()} image downloaded for {name} (app_id: {original_app_id})")
                    print(f"Image saved at: {dest_path}")
                else:
                    print(f"Failed to download {image_type.capitalize()} image for {name} (app_id: {original_app_id})")
            else:
                print(f"No {image_type.capitalize()} image found for {name} (app_id: {original_app_id})")

    def delete_library_cache(app_id):
        steam_root = os.path.expanduser("~/.local/share/Steam")
        cache_dir = os.path.join(steam_root, f"appcache/librarycache/{app_id}")
        if os.path.exists(cache_dir):
            shutil.rmtree(cache_dir)
            print(f"Library cache deleted for app_id: {app_id}")
        else:
            print(f"No library cache found for app_id: {app_id}")

    def parse_shortcuts(file_path):
        processed_app_ids = load_processed_app_ids()
        new_app_ids = set()

        with open(file_path, 'rb') as f:
            shortcuts = vdf.binary_load(f)
            for shortcut in shortcuts['shortcuts'].values():
                try:
                    original_app_id = abs(shortcut['appid'])  # Use abs() to remove negative sign
                    name = shortcut['AppName']
                    exe = shortcut['Exe']
                    print(f"Processing {name} (original_app_id: {original_app_id})...")
                    steam_id = search_images_by_name(name)
                    if steam_id:
                        create_library_cache(steam_id, original_app_id, name, exe)  # Create library cache with original app_id
                        new_app_ids.add(original_app_id)  # Track new app IDs using the original app_id
                    else:
                        print(f"SteamGridDB ID not found for {name} (original_app_id: {original_app_id})")
                    print(f"{original_app_id},{name},{exe}")
                except KeyError as e:
                    print(f"KeyError: {e} not found in {shortcut}")

        # Save new app IDs to file
        save_processed_app_ids(new_app_ids)

        # Delete library cache folders for processed shortcuts that no longer exist
        for app_id in processed_app_ids:
            if app_id not in new_app_ids:
                delete_library_cache(app_id)

    if len(sys.argv) < 2:
        file_path = find_shortcuts_vdf()
    else:
        file_path = sys.argv[1]
    
    check_games_available(file_path)
    print(f"Games available at: {file_path}")
    parse_shortcuts(file_path)

if __name__ == '__main__':
    main()

