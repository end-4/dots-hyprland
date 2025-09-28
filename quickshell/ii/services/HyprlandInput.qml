// Файл: quickshell/ii/services/HyprlandInput.qml
pragma Singleton
import QtQuick
import Quickshell

// Этот сервис будет напрямую работать с Hyprland для получения и установки настроек ввода.
// pragma Singleton делает его доступным глобально как "HyprlandInput".
Item {
    id: root

    // Сигнал, который сообщает интерфейсу, что настройки загружены/изменились
    signal settingsChanged()

    // Свойства для хранения наших настроек
    property string p_kb_layout: "us,ru"
    property string p_kb_options: "grp:alt_shift_toggle"
    property bool p_natural_scroll: false
    property bool p_tap_to_click: false
    property bool p_disable_while_typing: false
    property bool p_numlock_by_default: false

    // Функция для загрузки всех настроек из Hyprland
    function load() {
        // Используем hyprctl для получения текущих активных значений
        Quickshell.exec("hyprctl getoption input:kb_layout", function(stdout) {
            if (stdout.includes("str =")) {
                root.p_kb_layout = stdout.split("str = ")[1].trim().replace(/"/g, '');
            }
        });
        Quickshell.exec("hyprctl getoption input:kb_options", function(stdout) {
            if (stdout.includes("str =")) {
                root.p_kb_options = stdout.split("str = ")[1].trim().replace(/"/g, '');
            }
        });
        Quickshell.exec("hyprctl getoption input:natural_scroll", function(stdout) {
            root.p_natural_scroll = stdout.includes("int = 1");
        });
        Quickshell.exec("hyprctl getoption input:touchpad:tap-to-click", function(stdout) {
             root.p_tap_to_click = stdout.includes("int = 1");
        });
        Quickshell.exec("hyprctl getoption input:touchpad:disable_while_typing", function(stdout) {
             root.p_disable_while_typing = stdout.includes("int = 1");
        });
        // Последняя команда посылает сигнал, что всё загружено
        Quickshell.exec("hyprctl getoption input:numlock_by_default", function(stdout) {
             root.p_numlock_by_default = stdout.includes("int = 1");
             settingsChanged();
        });
    }
    
    // Функция для сохранения ОДНОЙ настройки
    function save(key, value) {
        let command = `hyprctl keyword input:${key} ${value}`;
        if (key.startsWith("tap-to-click") || key.startsWith("disable_while_typing")) {
            command = `hyprctl keyword input:touchpad:${key.replace(/_/g, '-')} ${value}`;
        }
        Quickshell.execDetached([ "bash", "-c", command ]);
    }
    
    // --- Новые функции для управления списком раскладок ---
    function addLayout(layout) {
        p_kb_layout_list.push(layout);
        saveLayoutList();
        settingsChanged(); // Сообщаем UI, что модель изменилась
    }
    
    function removeLayout(index) {
        if (index >= 0 && index < p_kb_layout_list.length) {
            p_kb_layout_list.splice(index, 1);
            saveLayoutList();
            settingsChanged(); // Сообщаем UI, что модель изменилась
        }
    }
    
    function saveLayoutList() {
        // Превращаем список ["us", "ru"] обратно в строку "us,ru" и сохраняем
        const layoutString = p_kb_layout_list.join(',');
        save("kb_layout", layoutString);
    }
}