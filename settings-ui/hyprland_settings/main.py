# hyprland-settings/main.py
import sys
import locale
import os
import re # Импортируем модуль для регулярных выражений
import subprocess
import json
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterSingletonInstance, qmlRegisterSingletonType
from PySide6.QtCore import QObject, Slot, Signal, QTimer, QUrl, Property, QVariantAnimation, QTranslator, QLocale


# --- Новая функция для генерации темы ---
def generate_theme_colors():
    """Запускает скрипт для генерации и сохранения цветовой схемы."""
    try:
        script_path = Path(__file__).parent / "generate_colors.py"
        if not script_path.exists():
            print(f"Warning: Color generation script not found at {script_path}")
            return
        subprocess.run([sys.executable, str(script_path)], check=True, capture_output=True, text=True)
        print("Successfully generated color theme.")
    except subprocess.CalledProcessError as e:
        print(f"Error running color generation script: {e}")
        print(f"Stderr: {e.stderr}")
    except Exception as e:
        print(f"An unexpected error occurred during color generation: {e}")

# --- Новый класс для управления темой ---
class ThemeManager(QObject):
    themeChanged = Signal()

    def __init__(self):
        super().__init__()
        self._theme = self._load_default_theme()
        self.load_theme_from_file()

    def _load_default_theme(self):
        # Цвета по умолчанию на случай, если theme.json не найден
        return {
            "background": "#161217", "surface": "#231E23", "surfaceHigh": "#2D282E",
            "primary": "#E5B6F2", "text": "#EAE0E7", "subtext": "#988E97",
            "outline": "#4C444D", "error": "#FFB4AB"
        }

    @Slot()
    def load_theme_from_file(self):
        theme_path = Path.home() / ".config/hyprland-settings/theme.json"
        if theme_path.exists():
            try:
                with open(theme_path, "r") as f:
                    self._theme = json.load(f)
                self.themeChanged.emit()
                print("Successfully loaded theme from theme.json")
            except (json.JSONDecodeError, IOError) as e:
                print(f"Could not load theme.json: {e}. Using default theme.")
                self._theme = self._load_default_theme()
                self.themeChanged.emit()

    @Property('QVariantMap', notify=themeChanged)
    def theme(self):
        return self._theme



HYPRLAND_DISPATCHERS = [
    'exec', 'pass', 'killactive', 'closewindow', 'workspace', 'movetoworkspace',
    'movetoworkspacesilent', 'togglefloating', 'fullscreen', 'pseudo', 'pin',
    'movefocus', 'movewindow', 'swapwindow', 'centerwindow', 'resizewindow',
    'movecursor', 'renameworkspace', 'exit', 'splittoggle', 'layoutmsg', 'submap',
    'togglegroup', 'changegroupactive', 'focusmonitor', 'movecursortocorner',
    'focuswindow', 'moveintogroup', 'moveoutofgroup', 'movewindoworgroup',
    'swapactiveworkspaces', 'bringactivetotop', 'alterzorder', 'dpms',
    'togglespecialworkspace', 'focusurgentorlast', 'global', 'splitratio',
    'fullscreenstate', 'cyclenext', 'resizeactive'
]

KEY_NAME_MAP = {
    "L_SHIFT": "Left Shift", "R_SHIFT": "Right Shift",
    "L_CTRL": "Left Ctrl", "R_CTRL": "Right Ctrl",
    "L_ALT": "Left Alt", "R_ALT": "Right Alt",
    "SUPER": "Super", "SHIFT": "Shift", "CTRL": "Ctrl", "ALT": "Alt",
}

def format_key_display(key_parts):
    # ИСПРАВЛЕНО: Правильно объединяем части для отображения
    return " + ".join([KEY_NAME_MAP.get(part.upper(), part) for part in key_parts])

class HyprlandBridge(QObject):
    keybindsChanged = Signal()

    def __init__(self):
        super().__init__()
        self.keybinds_file = Path.home() / ".config/hypr/hyprland/keybinds.conf"
        self.keybinds_file.parent.mkdir(parents=True, exist_ok=True)
        self.keybinds_file.touch()
        self._keybinds_cache = []
        self.load_keybinds()

    # --- ИСПРАВЛЕНИЕ: Полностью переработанный парсер ---
    def _parse_line(self, line):
        try:
            original_line = line.strip()
            if not original_line or not original_line.startswith('bind') or '=' not in original_line:
                return None

            parse_line = original_line
            title = ""
            if '#' in parse_line:
                parse_line, title = parse_line.split('#', 1)
                title = title.strip()

            if '=' not in parse_line: return None

            parts_str = parse_line.split('=', 1)[1].strip()
            parts = [p.strip() for p in parts_str.split(',')]

            dispatcher_index = -1
            for i, part in enumerate(parts):
                if not part: continue
                potential_dispatcher = part.split(None, 1)[0]
                if potential_dispatcher in HYPRLAND_DISPATCHERS:
                    dispatcher_index = i
                    break

            if dispatcher_index == -1: return None

            key_parts_raw = [p for p in parts[:dispatcher_index] if p]
            command_parts_raw = [p for p in parts[dispatcher_index:] if p]

            if not key_parts_raw or not command_parts_raw: return None

            # Разбираем блок клавиш (например, "SUPER+ALT", "J")
            final_key_parts_for_display = []
            for part in key_parts_raw:
                final_key_parts_for_display.extend(part.split('+'))

            return {
                "title": title,
                "key_display": format_key_display(final_key_parts_for_display),
                "command_display": ",".join(command_parts_raw),
                "key_raw": ",".join(key_parts_raw), # Это теперь "SUPER+ALT,J"
                "command_raw": ",".join(command_parts_raw),
                "original_line": original_line
            }
        except Exception as e:
            print(f"Failed to parse line '{line.strip()}': {e}", file=sys.stderr)
            return None

    @Slot()
    def load_keybinds(self):
        binds = []
        try:
            with open(self.keybinds_file, "r", encoding='utf-8') as f:
                for line in f:
                    parsed_bind = self._parse_line(line)
                    if parsed_bind:
                        binds.append(parsed_bind)
        except Exception as e:
            print(f"Error reading keybinds file: {e}", file=sys.stderr)

        self._keybinds_cache = binds
        self.keybindsChanged.emit()

    @Slot(result='QVariantList')
    def getKeybinds(self):
        return self._keybinds_cache

    # --- ИСПРАВЛЕНИЕ: Добавлена проверка от пустой строки ---
    @Slot(str, str, result='QVariantMap')
    def checkIfKeybindExists(self, key_to_check, original_line_to_ignore):
        if not key_to_check: # Не проверять, если строка пустая
            return None
        try:
            with open(self.keybinds_file, "r", encoding='utf-8') as f:
                for line in f:
                    if line.strip() == original_line_to_ignore:
                        continue

                    parsed_bind = self._parse_line(line)
                    if parsed_bind and parsed_bind["key_raw"] == key_to_check:
                        return parsed_bind
        except Exception as e:
            print(f"Error checking keybind existence: {e}", file=sys.stderr)
        return None

    @Slot(str, str, str)
    def addKeybind(self, key, command, title):
        self.setKeybind("", key, command, title)

    @Slot(str, str, str, str)
    def updateKeybind(self, original_line, new_key, command, title):
        self.setKeybind(original_line, new_key, command, title)

    # --- ИСПРАВЛЕНИЕ: Улучшенная логика добавления 'exec' ---
    @Slot(str, str, str, str)
    def setKeybind(self, original_line, new_key, command, title):
        try:
            final_command = command.strip()
            # Проверяем, начинается ли команда с известного диспетчера
            first_word = final_command.split(',')[0].strip().split(' ')[0]
            if first_word not in HYPRLAND_DISPATCHERS:
                final_command = f"exec, {final_command}"

            lines = self.keybinds_file.read_text(encoding='utf-8').splitlines()

            if original_line:
                lines = [line for line in lines if line.strip() != original_line]

            new_line = f"bind = {new_key}, {final_command}"
            if title:
                new_line += f" # {title}"

            lines.append(new_line)
            self.keybinds_file.write_text("\n".join(lines) + "\n", encoding='utf-8')

            if original_line:
                parsed_original = self._parse_line(original_line)
                if parsed_original:
                    original_key = parsed_original.get("key_raw")
                    if original_key and original_key != new_key:
                        subprocess.run(["hyprctl", "keyword", "unbind", original_key], check=False, capture_output=True)

            subprocess.run(["hyprctl", "keyword", "bind", f"{new_key},{final_command}"], check=False, capture_output=True)

            QTimer.singleShot(100, self.load_keybinds)
        except Exception as e:
            print(f"Error setting keybind: {e}", file=sys.stderr)

    @Slot(str)
    def removeKeybind(self, original_line):
        try:
            lines = self.keybinds_file.read_text(encoding='utf-8').splitlines()

            key_to_unbind = ""
            parsed_bind = self._parse_line(original_line)
            if parsed_bind:
                key_to_unbind = parsed_bind.get("key_raw")

            lines = [line for line in lines if line.strip() != original_line]
            self.keybinds_file.write_text("\n".join(lines) + "\n", encoding='utf-8')

            if key_to_unbind:
                subprocess.run(["hyprctl", "keyword", "unbind", key_to_unbind], check=False, capture_output=True)

            QTimer.singleShot(100, self.load_keybinds)
        except Exception as e:
            print(f"Error removing keybind: {e}", file=sys.stderr)

class AutostartBridge(QObject):
    autostartChanged = Signal()

    def __init__(self):
        super().__init__()
        self.system_execs_file = Path.home() / ".config/hypr/hyprland/execs.conf"
        self.user_execs_file = Path.home() / ".config/hypr/custom/execs.conf"

        self.user_execs_file.parent.mkdir(parents=True, exist_ok=True)
        self.user_execs_file.touch()

        self._autostart_cache = []
        self.load_autostart_entries()

    def _parse_exec_line(self, line, is_system):
        original_line = line.strip()
        if not original_line or not original_line.startswith("exec-once"):
            return None

        parse_line = original_line
        title = ""
        if '#' in parse_line:
            parse_line, title = parse_line.split('#', 1)
            title = title.strip()

        if '=' not in parse_line:
            return None

        command = parse_line.split('=', 1)[1].strip()

        return {
            "title": title,
            "command": command,
            "is_system": is_system,
            "original_line": original_line
        }

    @Slot()
    def load_autostart_entries(self):
        entries = []
        try:
            if self.system_execs_file.exists():
                with open(self.system_execs_file, "r", encoding='utf-8') as f:
                    for line in f:
                        entry = self._parse_exec_line(line, True)
                        if entry:
                            entries.append(entry)

            with open(self.user_execs_file, "r", encoding='utf-8') as f:
                for line in f:
                    entry = self._parse_exec_line(line, False)
                    if entry:
                        entries.append(entry)

        except Exception as e:
            print(f"Error reading autostart files: {e}", file=sys.stderr)

        self._autostart_cache = entries
        self.autostartChanged.emit()

    @Slot(result='QVariantList')
    def getAutostartEntries(self):
        return self._autostart_cache

    def _write_execs(self, file_path, lines):
        file_path.write_text("\n".join(lines) + "\n", encoding='utf-8')
        subprocess.run(["flatpak-spawn", "--host", "hyprctl", "reload"], check=False, capture_output=True)
        QTimer.singleShot(100, self.load_autostart_entries)

    @Slot(str, str)
    def addAutostart(self, command, title):
        new_line = f"exec-once = {command}"
        if title:
            new_line += f" # {title}"

        try:
            lines = self.user_execs_file.read_text(encoding='utf-8').splitlines()
            lines.append(new_line)
            self._write_execs(self.user_execs_file, lines)
        except Exception as e:
            print(f"Error adding autostart: {e}", file=sys.stderr)

    @Slot(str, str, str)
    def updateAutostart(self, original_line, command, title):
        new_line = f"exec-once = {command}"
        if title:
            new_line += f" # {title}"

        try:
            user_lines = self.user_execs_file.read_text(encoding='utf-8').splitlines()
            for i, line in enumerate(user_lines):
                if line.strip() == original_line:
                    user_lines[i] = new_line
                    self._write_execs(self.user_execs_file, user_lines)
                    return

            if self.system_execs_file.exists():
                system_lines = self.system_execs_file.read_text(encoding='utf-8').splitlines()
                for i, line in enumerate(system_lines):
                    if line.strip() == original_line:
                        system_lines[i] = new_line
                        self._write_execs(self.system_execs_file, system_lines)
                        return

            print(f"Warning: original_line for update not found. Appending to user file.", file=sys.stderr)
            self.addAutostart(command, title)

        except Exception as e:
            print(f"Error updating autostart: {e}", file=sys.stderr)

    @Slot(str)
    def removeAutostart(self, original_line):
        try:
            user_lines = self.user_execs_file.read_text(encoding='utf-8').splitlines()
            user_lines_stripped = [line.strip() for line in user_lines]
            if original_line in user_lines_stripped:
                final_lines = [line for line in user_lines if line.strip() != original_line]
                self._write_execs(self.user_execs_file, final_lines)
                return

            if self.system_execs_file.exists():
                system_lines = self.system_execs_file.read_text(encoding='utf-8').splitlines()
                system_lines_stripped = [line.strip() for line in system_lines]
                if original_line in system_lines_stripped:
                    final_lines = [line for line in system_lines if line.strip() != original_line]
                    self._write_execs(self.system_execs_file, final_lines)
                    return

            print(f"Warning: original_line for removal not found: '{original_line}'", file=sys.stderr)

        except Exception as e:
            print(f"Error removing autostart: {e}", file=sys.stderr)

# ===============================================================
# НОВЫЙ КЛАСС: WindowRulesBridge
# ===============================================================
class WindowRulesBridge(QObject):
    rulesChanged = Signal()

    def __init__(self):
        super().__init__()
        self.rules_file = Path.home() / ".config/hypr/hyprland/rules.conf"
        self.rules_file.parent.mkdir(parents=True, exist_ok=True)
        self.rules_file.touch()
        self._rules_cache = []
        self.load_rules()

    def _parse_rule_line(self, line):
        original_line = line.strip()
        if not original_line or not (original_line.startswith("windowrule") or original_line.startswith("windowrulev2")):
            return None

        parse_line = original_line
        comment = ""
        if '#' in parse_line:
            parse_line, comment = parse_line.split('#', 1)
            comment = comment.strip()

        # Удаляем 'windowrule=' или 'windowrulev2=' и разделяем по запятой
        parts_str = re.sub(r'windowrulev?2\s*=\s*', '', parse_line).strip()
        parts = [p.strip() for p in parts_str.split(',')]

        if not parts:
            return None

        # Первые части - это действие и его параметры
        action = parts[0].split()[0]
        params = parts[0].split()[1:]

        # Все последующие части - это критерии окна
        target_parts = parts[1:]

        # --- Логика для отображения ---
        description = f"{action.capitalize()} {' '.join(params)}".strip()
        target_description = ", ".join(target_parts)

        # --- Логика для парсинга в диалог ---
        parsed_data = {
            "action": action,
            "params": params,
            "target_type": "class", # Значение по умолчанию
            "target_value": "",
            "exact_match": False
        }
        if target_parts:
            # Берем первый критерий для простоты отображения
            # (в реальности их может быть несколько)
            main_target = target_parts[0]
            if ':' in main_target:
                ttype, tval = main_target.split(':', 1)
                parsed_data["target_type"] = ttype.strip()
                parsed_data["target_value"] = tval.strip()
                if tval.strip().startswith('^(') and tval.strip().endswith(')$'):
                    parsed_data["exact_match"] = True
                    parsed_data["target_value"] = tval.strip()[2:-2]
            else: # для boolean-критериев
                parsed_data["target_type"] = main_target

        return {
            "description": description,
            "target": target_description,
            "comment": comment,
            "original_line": original_line,
            "parsed": parsed_data
        }

    @Slot()
    def load_rules(self):
        rules = []
        try:
            with open(self.rules_file, "r", encoding='utf-8') as f:
                for line in f:
                    parsed_rule = self._parse_rule_line(line)
                    if parsed_rule:
                        rules.append(parsed_rule)
        except Exception as e:
            print(f"Error reading window rules file: {e}", file=sys.stderr)

        self._rules_cache = rules
        self.rulesChanged.emit()

    @Slot(result='QVariantList')
    def getRules(self):
        return self._rules_cache

    def _write_rules(self, lines):
        self.rules_file.write_text("\n".join(lines) + "\n", encoding='utf-8')
        subprocess.run(["flatpak-spawn", "--host", "hyprctl", "reload"], check=False, capture_output=True)
        QTimer.singleShot(100, self.load_rules)

    @Slot('QVariantMap')
    def addRule(self, rule_data):
        self.setRule("", rule_data)

    @Slot(str, 'QVariantMap')
    def updateRule(self, original_line, rule_data):
        self.setRule(original_line, rule_data)

    def setRule(self, original_line, rule_data):
        # 1. Собираем действие и параметры
        action_part = rule_data['action']
        if rule_data['params']:
            action_part += f" {' '.join(rule_data['params'])}"

        # 2. Собираем критерий окна
        target_type = rule_data['target_type']
        target_value = rule_data['target_value']

        target_part = ""
        # boolean-критерии
        if target_type in ["floating", "tiled", "pinned", "fullscreen", "xwayland"]:
            target_part = f", {target_type}"
        # критерии со значением
        elif target_value:
            if rule_data['exact_match'] and target_type in ["class", "initialClass", "title", "initialTitle"]:
                target_part = f", {target_type}:^({re.escape(target_value)})$"
            else:
                target_part = f", {target_type}:{target_value}"

        if not target_part:
            print("Error: Window rule must have a target.", file=sys.stderr)
            return

        new_line = f"windowrule = {action_part}{target_part}"
        if rule_data['comment']:
            new_line += f" # {rule_data['comment']}"

        try:
            lines = self.rules_file.read_text(encoding='utf-8').splitlines()
            if original_line:
                lines = [line for line in lines if line.strip() != original_line]

            lines.append(new_line)
            self._write_rules(lines)
        except Exception as e:
            print(f"Error setting window rule: {e}", file=sys.stderr)

    @Slot(str)
    def removeRule(self, original_line):
        try:
            lines = self.rules_file.read_text(encoding='utf-8').splitlines()
            lines = [line for line in lines if line.strip() != original_line]
            self._write_rules(lines)
        except Exception as e:
            print(f"Error removing window rule: {e}", file=sys.stderr)

# ===============================================================
# НОВЫЙ КЛАСС: DisplaysBridge
# ===============================================================
class DisplaysBridge(QObject):
    monitorsChanged = Signal()

    def __init__(self):
        super().__init__()
        self._monitors_cache = []
        self.load_monitors()

    @Slot()
    def load_monitors(self):
        """Загружает и кэширует информацию о дисплеях из hyprctl."""
        try:
            result = subprocess.run(
                ["hyprctl", "monitors", "-j"],
                check=True, capture_output=True, text=True, encoding='utf-8'
            )
            monitors_data = json.loads(result.stdout)
            
            # Обогащаем данные мониторов дополнительной информацией
            for monitor in monitors_data:
                # Убеждаемся, что все необходимые поля присутствуют
                if 'disabled' not in monitor:
                    monitor['disabled'] = not monitor.get('active', True)
                if 'transform' not in monitor:
                    monitor['transform'] = 0
                if 'mirrorSource' not in monitor:
                    monitor['mirrorSource'] = ""
                if 'vrr' not in monitor:
                    monitor['vrr'] = 0
                if 'bitdepth' not in monitor:
                    monitor['bitdepth'] = 8
                if 'colorManagement' not in monitor:
                    monitor['colorManagement'] = "auto"
                if 'sdrBrightness' not in monitor:
                    monitor['sdrBrightness'] = 1.0
                if 'sdrSaturation' not in monitor:
                    monitor['sdrSaturation'] = 1.0
                if 'reservedTop' not in monitor:
                    monitor['reservedTop'] = 0
                if 'reservedBottom' not in monitor:
                    monitor['reservedBottom'] = 0
                if 'reservedLeft' not in monitor:
                    monitor['reservedLeft'] = 0
                if 'reservedRight' not in monitor:
                    monitor['reservedRight'] = 0
                
                # Получаем доступные режимы для каждого монитора
                try:
                    modes_result = subprocess.run(
                        ["hyprctl", "monitors", "all"],
                        check=True, capture_output=True, text=True, encoding='utf-8'
                    )
                    # Парсим доступные режимы из вывода
                    monitor['availableModes'] = self._parse_available_modes(modes_result.stdout, monitor['name'])
                except Exception as e:
                    print(f"Warning: Could not get available modes for {monitor.get('name', 'unknown')}: {e}")
                    monitor['availableModes'] = []
            
            self._monitors_cache = monitors_data
        except (subprocess.CalledProcessError, json.JSONDecodeError, FileNotFoundError) as e:
            print(f"Error getting monitors from hyprctl: {e}", file=sys.stderr)
            self._monitors_cache = []
        
        self.monitorsChanged.emit()

    def _parse_available_modes(self, hyprctl_output, monitor_name):
        """Парсит доступные режимы из вывода hyprctl monitors all"""
        modes = []
        try:
            lines = hyprctl_output.split('\n')
            in_monitor_section = False
            
            for line in lines:
                if f"Monitor {monitor_name}" in line:
                    in_monitor_section = True
                    continue
                elif line.startswith("Monitor ") and in_monitor_section:
                    # Начался другой монитор, выходим
                    break
                elif in_monitor_section and "@" in line and "x" in line:
                    # Ищем строки с режимами вида "1920x1080@60.00"
                    mode_match = re.search(r'(\d+x\d+@[\d.]+)', line)
                    if mode_match:
                        modes.append(mode_match.group(1))
        except Exception as e:
            print(f"Error parsing available modes: {e}")
        
        return modes

    @Slot(result='QVariantList')
    def getMonitors(self):
        """Возвращает кэшированный список мониторов в QML."""
        return self._monitors_cache

    @Slot('QVariantList')
    def applyMonitorSettings(self, configs):
        """Применяет настройки для всех мониторов одной командой."""
        if not configs:
            print("No monitor configs to apply.", file=sys.stderr)
            return
        
        try:
            # Формируем одну большую команду для --batch
            batch_command = ""
            for config_str in configs:
                # config_str имеет формат "DP-1,1920x1080@60,0x0,1"
                # Мы должны обернуть это в "keyword monitor ..."
                batch_command += f"keyword monitor {config_str};"

            print(f"Executing batch monitor command: {batch_command}") # Для отладки

            subprocess.run(
                ["hyprctl", "--batch", batch_command],
                check=True, capture_output=True, text=True, encoding='utf-8'
            )
            # После применения настроек, перезагружаем информацию
            QTimer.singleShot(200, self.load_monitors)

        except subprocess.CalledProcessError as e:
            print(f"Error applying monitor settings: {e}", file=sys.stderr)
            print(f"Stderr: {e.stderr}", file=sys.stderr)
        except Exception as e:
            print(f"An unexpected error occurred while applying monitor settings: {e}", file=sys.stderr)

def main():
    generate_theme_colors()

    app = QGuiApplication(sys.argv)

    class LanguageManager(QObject):
        languageChanged = Signal()

        def __init__(self, engine, qml_url):
            super().__init__()
            self.engine = engine
            self.qml_url = qml_url
            self.translator = None # Инициализируем как None
            self.i18n_dir = Path("/app/share/hyprland-settings-i18n") if os.environ.get('FLATPAK_ID') else Path(__file__).parent / "i18n"
            self.config_path = Path.home() / ".config/hyprland-settings/config.json"
            self.config_path.parent.mkdir(parents=True, exist_ok=True)
            
            self.retranslate_dummy = 0

            self._available_translations = self._scan_translations()

            import_locale = os.environ.get('LANG', locale.getlocale()[0])
            if import_locale is None:
                import_locale = 'en_US.UTF-8'
                
            lang_code = import_locale.split('_')[0].lower()

            supported_locales = {
                'ru': 'ru_RU', 'en': 'en_US', 'it': 'it_IT',
                'uk': 'uk_UA', 'zh': 'zh_CN', 'ja': 'ja_JP'
            }
            
            detected = supported_locales.get(lang_code, 'en_US')
            self.current_locale = detected

            saved_locale = self._load_saved_language()
            if saved_locale:
                for trans in self._available_translations:
                    if trans['locale'] == saved_locale:
                        self.current_locale = saved_locale
                        break

            self.setLanguage(self.current_locale)

        def _load_saved_language(self):
            if self.config_path.exists():
                try:
                    with open(self.config_path, "r") as f:
                        config = json.load(f)
                        return config.get("language")
                except (json.JSONDecodeError, IOError):
                    pass
            return None

        def _scan_translations(self):
            """Scan i18n directory for available .qm files and return list of dicts."""
            qm_map = {
                "app_en.qm": {"display": "English", "locale": "en_US"},
                "app_ru.qm": {"display": "Russian", "locale": "ru_RU"},
                "app_it.qm": {"display": "Italian", "locale": "it_IT"},
                "app_uk.qm": {"display": "Ukrainian", "locale": "uk_UA"},
                "app_zh_CN.qm": {"display": "Chinese", "locale": "zh_CN"},
                "app_ja.qm": {"display": "Japanese", "locale": "ja_JP"},
            }
            translations = []
            for qm_file, info in qm_map.items():
                if (self.i18n_dir / qm_file).exists():
                    translations.append(info)
            return translations

        def _save_language(self, locale_str):
            config = {"language": locale_str}
            try:
                with open(self.config_path, "w") as f:
                    json.dump(config, f)
            except IOError as e:
                print(f"Failed to save language config: {e}")
        
        @Property(int, notify=languageChanged)
        def retranslateDummy(self):
            return self.retranslate_dummy

        @Property(str, notify=languageChanged)
        def currentLocale(self):
            return self.current_locale

        @Property('QVariantList', notify=languageChanged)
        def availableTranslations(self):
            return self._available_translations
    
        @Slot(str)
        def setLanguage(self, locale_str):
            print(f"Attempting to set language to: {locale_str}")

            if self.current_locale == locale_str and self.translator:
                print("Language already set. Skipping.")
                return

            # Удаляем старый переводчик, если он был
            if self.translator:
                app.removeTranslator(self.translator)
                print("Removed old translator.")

            locale_to_qm = {
                "en_US": "app_en.qm", "it_IT": "app_it.qm", "uk_UA": "app_uk.qm",
                "zh_CN": "app_zh_CN.qm", "ja_JP": "app_ja.qm", "ru_RU": "app_ru.qm"
            }
    
            qm_filename = locale_to_qm.get(locale_str, "app_en.qm")
            qm_file = self.i18n_dir / qm_filename
            print(f"Looking for translation file: {qm_file}")
    
            if qm_file.exists():
                # Создаем НОВЫЙ экземпляр переводчика
                self.translator = QTranslator()
                loaded = self.translator.load(str(qm_file))
                if loaded:
                    app.installTranslator(self.translator)
                    print(f"Successfully loaded and installed translator for {locale_str}")
                else:
                    print(f"ERROR: Failed to load {qm_file} for locale {locale_str}")
                    self.translator = None # Сбрасываем, если не удалось загрузить
            else:
                print(f"ERROR: Translation file not found: {qm_file}")
                self.translator = None
    
            locale_parts = locale_str.split('_')
            if len(locale_parts) == 2:
                language_map = {
                    "en": QLocale.English, "it": QLocale.Italian, "uk": QLocale.Ukrainian,
                    "zh": QLocale.Chinese, "ja": QLocale.Japanese, "ru": QLocale.Russian,
                }
                lang_code = locale_parts[0].lower()
                language = language_map.get(lang_code, QLocale.English)
    
                country_map = {
                    "us": QLocale.UnitedStates, "it": QLocale.Italy, "ua": QLocale.Ukraine,
                    "cn": QLocale.China, "jp": QLocale.Japan, "ru": QLocale.Russia,
                }
                country_code = locale_parts[1].lower()
                country = country_map.get(country_code, QLocale.UnitedStates)
                QLocale.setDefault(QLocale(language, country))
            else:
                QLocale.setDefault(QLocale.English)
    
            self.current_locale = locale_str
            self._save_language(locale_str)
            
            self.retranslate_dummy += 1
            self.languageChanged.emit()
            
    engine = QQmlApplicationEngine()

    qml_dir = Path("/app/share/hyprland-settings-qml") if os.environ.get('FLATPAK_ID') else Path(__file__).parent / "qml"
    qml_file_url = QUrl.fromLocalFile(str(qml_dir / "main.qml"))
    qmlRegisterSingletonType(QUrl.fromLocalFile(str(qml_dir / "Theme.qml")), "App", 1, 0, "Theme")

    engine.addImportPath(str(qml_dir))
    engine.addImportPath(str(qml_dir / "Components"))
    engine.addImportPath(str(qml_dir / "Components" / "Controls"))

    lang_manager = LanguageManager(engine, qml_file_url)
    engine.rootContext().setContextProperty("LanguageManager", lang_manager)

    theme_manager = ThemeManager()
    engine.rootContext().setContextProperty("ThemeManager", theme_manager)

    hyprland_bridge = HyprlandBridge()
    engine.rootContext().setContextProperty("HyprlandBridge", hyprland_bridge)

    autostart_bridge = AutostartBridge()
    engine.rootContext().setContextProperty("AutostartBridge", autostart_bridge)

    window_rules_bridge = WindowRulesBridge()
    engine.rootContext().setContextProperty("WindowRulesBridge", window_rules_bridge)

    # --- РЕГИСТРАЦИЯ НОВОГО BRIDGE ДЛЯ ДИСПЛЕЕВ ---
    displays_bridge = DisplaysBridge()
    engine.rootContext().setContextProperty("DisplaysBridge", displays_bridge)

    engine.load(qml_file_url)

    if not engine.rootObjects():
        print("Failed to load QML. Check console for specific errors.", file=sys.stderr)
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()