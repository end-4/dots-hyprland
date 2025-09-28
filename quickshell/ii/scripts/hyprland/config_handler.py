#!/usr/bin/env python3

import os
import sys
import json
import re

# --- Настройки ---
# Ключи, которые мы ищем в конфиге
KEYS_TO_MANAGE = {
    "kb_layout",
    "kb_options",
    "repeat_delay",
    "repeat_rate",
    "numlock_by_default",
    "natural_scroll",
    "tap-to-click",
    "disable_while_typing",
    "follow_mouse",
}

# --- Логика ---

def get_config_path():
    """Находит путь к файлу input.conf динамически."""
    return os.path.expanduser("~/.config/hypr/input.conf")

def read_settings():
    """Читает все значения из файла и возвращает их как словарь."""
    config_path = get_config_path()
    settings = {}
    try:
        with open(config_path, 'r') as f:
            for line in f:
                line = line.strip()
                if '=' in line and not line.startswith('#'):
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    if key in KEYS_TO_MANAGE:
                        # Преобразуем строковые 'true'/'false'/'yes'/'no'/'1'/'0' в булевы
                        if value.lower() in ['true', 'yes', '1']:
                            settings[key] = True
                        elif value.lower() in ['false', 'no', '0']:
                            settings[key] = False
                        else:
                            settings[key] = value
    except FileNotFoundError:
        print(f"Error: Config file not found at {config_path}", file=sys.stderr)
        return {}
    return settings

def write_setting(key, value):
    """Находит ключ в файле и заменяет его значение."""
    config_path = get_config_path()
    try:
        with open(config_path, 'r') as f:
            lines = f.readlines()

        new_lines = []
        key_found = False
        # Regex для поиска строки с ключом, учитывая отступы
        key_regex = re.compile(rf"^\s*{re.escape(key)}\s*=\s*.*")

        for line in lines:
            if key_regex.match(line):
                # Формируем новую строку с отступом
                indent = re.match(r"^\s*", line).group(0)
                new_lines.append(f"{indent}{key} = {value}\n")
                key_found = True
            else:
                new_lines.append(line)
        
        if not key_found:
             # Если ключ не найден, можно его добавить. Для простоты пока опустим.
             print(f"Warning: Key '{key}' not found in config. Cannot set value.", file=sys.stderr)
             return

        with open(config_path, 'w') as f:
            f.writelines(new_lines)

    except FileNotFoundError:
        print(f"Error: Config file not found at {config_path}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) == 2 and sys.argv[1] == '--get-all':
        # Команда для QML для получения всех настроек
        settings = read_settings()
        print(json.dumps(settings))

    elif len(sys.argv) == 4 and sys.argv[1] == '--set':
        # Команда для QML для установки одной настройки
        key_to_set = sys.argv[2]
        value_to_set = sys.argv[3]
        
        # Конвертируем обратно в формат, понятный Hyprland
        if value_to_set.lower() == 'true':
            value_for_config = 'true' if key_to_set == 'numlock_by_default' else 'yes'
            if key_to_set == 'follow_mouse': value_for_config = '1'
        elif value_to_set.lower() == 'false':
            value_for_config = 'false' if key_to_set == 'numlock_by_default' else 'no'
            if key_to_set == 'follow_mouse': value_for_config = '0'
        else:
            value_for_config = value_to_set

        write_setting(key_to_set, value_for_config)