#!/usr/bin/env python

import os
import sys
import json
import re

CONFIG_PATH = os.path.expanduser("~/.config/hypr/hypridle.conf")

def parse_conf(content):
    """Парсит содержимое hypridle.conf в структурированный словарь."""
    config = {"general": {}, "listeners": []}
    # Удаляем комментарии, сохраняя пустые строки для структуры
    content_no_comments = re.sub(r'#.*', '', content)

    # Используем regex для поиска всех блоков listener
    listener_blocks = re.findall(r'listener\s*\{([\s\S]*?)\}', content_no_comments, re.MULTILINE)
    
    for block in listener_blocks:
        listener = {}
        lines = block.strip().split('\n')
        for line in lines:
            line = line.strip()
            if '=' in line:
                key, value = line.split('=', 1)
                listener[key.strip()] = value.strip()
        if 'on-timeout' in listener: # Каждый listener должен иметь on-timeout
            config["listeners"].append(listener)

    # Парсим секцию general (если есть)
    general_match = re.search(r'general\s*\{([\s\S]*?)\}', content_no_comments, re.MULTILINE)
    if general_match:
        block = general_match.group(1)
        lines = block.strip().split('\n')
        for line in lines:
            line = line.strip()
            if '=' in line:
                key, value = line.split('=', 1)
                config["general"][key.strip()] = value.strip()

    return config

def get_config_as_json():
    """Читает конфиг и выводит его в формате JSON."""
    try:
        with open(CONFIG_PATH, 'r') as f:
            content = f.read()
        config_data = parse_conf(content)
        print(json.dumps(config_data, indent=4))
    except FileNotFoundError:
        print(json.dumps({"general": {}, "listeners": []}, indent=4))
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)

def set_config_value(action, key, value):
    """Обновляет, добавляет или удаляет listener."""
    try:
        with open(CONFIG_PATH, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        lines = []

    # Если value 'null', мы удаляем блок
    if value.lower() == 'null':
        new_lines = []
        in_block_to_delete = False
        for line in lines:
            if 'listener' in line and '{' in line:
                # Временный буфер для блока
                block_lines = [line]
                is_target_block = False
            elif in_block_to_delete:
                if '}' in line:
                    in_block_to_delete = False
                continue
            else:
                 new_lines.append(line)

            # Проверяем, наш ли это блок
            temp_block = "".join(lines[lines.index(line):])
            block_content_match = re.search(r'\{([\s\S]*?)\}', temp_block)
            if block_content_match:
                 block_content = block_content_match.group(1)
                 if f"on-timeout = {action}" in block_content:
                      in_block_to_delete = True
        lines = new_lines

    else: # Обновляем или добавляем
        found_block = False
        # Логика для поиска и обновления/добавления
        # Эта часть может быть сложной, поэтому для простоты добавим новый блок, а старый закомментируем
        
        # Удаляем старый блок
        output_lines = []
        in_matching_block = False
        brace_count = 0
        for line in lines:
            stripped_line = line.strip()
            if stripped_line.startswith('listener'):
                # Начинается блок listener, проверяем его содержимое
                # Это упрощенная проверка, которая может не справиться со сложными случаями
                temp_buffer = line
                temp_index = lines.index(line) + 1
                while temp_index < len(lines) and '}' not in lines[temp_index]:
                    temp_buffer += lines[temp_index]
                    temp_index += 1
                if temp_index < len(lines):
                    temp_buffer += lines[temp_index]

                if f'on-timeout = {action}' in temp_buffer:
                    # Это блок, который мы хотим заменить, пропускаем его
                    i = temp_index
                    while i < len(lines):
                        if '}' in lines[i]: break
                        i += 1
                    # Пропускаем строки этого блока
                    continue
            
            if in_matching_block:
                if '{' in stripped_line: brace_count += 1
                if '}' in stripped_line: brace_count -= 1
                if brace_count == 0: in_matching_block = False
            else:
                output_lines.append(line)

        # Добавляем новый блок в конец
        new_listener_block = [
            "\n",
            "listener {\n",
            f"    timeout = {value}\n",
            f"    on-timeout = {action}\n"
        ]
        # Добавляем on-resume для dpms
        if 'dpms off' in action:
             new_listener_block.append("    on-resume = hyprctl dispatch dpms on\n")
        new_listener_block.append("}\n")
        
        lines = output_lines + new_listener_block


    with open(CONFIG_PATH, 'w') as f:
        f.writelines(lines)
    
    # После изменения снова выводим актуальный JSON
    get_config_as_json()


if __name__ == "__main__":
    if len(sys.argv) == 1 or sys.argv[1] == '--get':
        get_config_as_json()
    elif sys.argv[1] == '--set' and len(sys.argv) == 5:
        # --set [action] [key] [value]
        # Например: --set 'loginctl lock-session' timeout 300
        _, _, action, key, value = sys.argv
        set_config_value(action, key, value)
    else:
        print("Usage: hypridle_adapter.py [--get] | [--set <action> <key> <value>]", file=sys.stderr)
        sys.exit(1)