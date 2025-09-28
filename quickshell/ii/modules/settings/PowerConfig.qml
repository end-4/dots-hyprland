import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

ContentPage {
    forceWidth: true

    // --- Константы и пути ---
    readonly property string confFile: CF.FileUtils.trimFileProtocol(Directories.config) + "/hypr/hypridle.conf"
    readonly property string adapterScript: "quickshell/ii/scripts/hyprland/hypridle_adapter.py"
    
    // Уникальные команды-идентификаторы для каждого действия
    readonly property string lockAction: "loginctl lock-session"
    readonly property string screenOffAction: "hyprctl dispatch dpms off"
    readonly property string suspendAction: "$suspend_cmd"

    // --- Свойства для хранения состояния ---
    property var config: ({ "listeners": [] }) // Основной объект с данными из JSON

    // --- Переменные для удобной привязки к UI ---
    property var lockListener: findListener(lockAction)
    property var screenOffListener: findListener(screenOffAction)
    property var suspendListener: findListener(suspendAction)

    // Функция для поиска listener в нашем объекте config
    function findListener(action) {
        if (!config.listeners) return null
        return config.listeners.find(listener => listener['on-timeout'] === action)
    }

    // --- Основные функции ---

    // 1. Функция ЧТЕНИЯ конфига
    function reloadConfig() {
        // Вызываем python-скрипт, который вернет нам JSON
        qs.Shell.exec(`${adapterScript} --get`, (stdout, stderr) => {
            if (stderr) {
                console.error("PowerConfig Error (reload): " + stderr)
                return
            }
            try {
                // Парсим полученный JSON и обновляем наш основной объект
                config = JSON.parse(stdout)
                // Принудительно обновляем переменные для UI
                lockListener = findListener(lockAction)
                screenOffListener = findListener(screenOffAction)
                suspendListener = findListener(suspendAction)
                console.log("PowerConfig: Config reloaded successfully.")
            } catch (e) {
                console.error("PowerConfig: Failed to parse JSON: " + e)
            }
        })
    }

    // 2. Функция ЗАПИСИ (включение или обновление listener)
    function setListener(action, timeoutMinutes) {
        const timeoutSeconds = timeoutMinutes * 60
        // Оборачиваем action в кавычки для безопасности в shell
        const safeAction = `'${action}'`
        
        let onResumeLine = ""
        if (action === screenOffAction) {
            onResumeLine = `    on-resume = hyprctl dispatch dpms on\\n`
        }

        // Команда bash:
        // 1. Проверяем с помощью grep, есть ли уже listener с таким on-timeout.
        // 2. Если есть (код возврата 0), то используем sed для замены только строки с timeout.
        // 3. Если нет, то используем echo для добавления нового блока listener в конец файла.
        const command = `bash -c "
            if grep -q 'on-timeout = ${action}' '${confFile}'; then 
                echo 'Listener found, updating timeout.'
                sed -i '/on-timeout = ${action}/,/^}/ s/timeout = .*/timeout = ${timeoutSeconds}/' '${confFile}';
            else
                echo 'Listener not found, adding new one.'
                echo -e '\\nlistener {\\n    timeout = ${timeoutSeconds}\\n    on-timeout = ${action}\\n${onResumeLine}}' >> '${confFile}';
            fi
        "`

        console.log("Executing set command: " + command)
        qs.Shell.exec(command, (stdout, stderr) => {
             if (stderr) console.error("PowerConfig Error (set): " + stderr)
             if (stdout) console.log("PowerConfig Info (set): " + stdout)
             // После успешной записи, перезагружаем конфиг, чтобы UI обновился
             reloadConfig()
        })
    }

    // 3. Функция УДАЛЕНИЯ listener
    function removeListener(action) {
        // Простая и надежная команда sed для удаления всего блока listener,
        // который содержит нужную строку on-timeout.
        const command = `sed -i '/on-timeout = ${action}/,/^}/d' '${confFile}'`

        console.log("Executing remove command: " + command)
        qs.Shell.exec(command, (stdout, stderr) => {
            if (stderr) console.error("PowerConfig Error (remove): " + stderr)
            // После успешного удаления, перезагружаем конфиг
            reloadConfig()
        })
    }

    // --- Инициализация ---
    Component.onCompleted: {
        reloadConfig()
    }

    // --- UI Секции ---
    ContentSection {
        icon: "lock"
        title: "Screen Lock"

        ConfigSwitch {
            checked: lockListener !== null && lockListener !== undefined
            onCheckedChanged: {
                if (checked) {
                    setListener(lockAction, lockTimeoutSpinBox.value)
                } else {
                    removeListener(lockAction)
                }
            }
        }

        ConfigSpinBox {
            id: lockTimeoutSpinBox
            text: "Timeout (minutes)"
            from: 1
            to: 120
            stepSize: 1
            value: lockListener ? (lockListener.timeout / 60) : 5
            enabled: parent.parent.lockListener !== null && parent.parent.lockListener !== undefined
            // onValueChanged срабатывает при изменении значения кнопками +/- или вводом
            onValueChanged: {
                if (enabled) {
                    setListener(lockAction, value)
                }
            }
        }
    }

    ContentSection {
        icon: "desktop_windows"
        title: "Screen Off"

        ConfigSwitch {
            checked: screenOffListener !== null && screenOffListener !== undefined
            onCheckedChanged: {
                if (checked) {
                    setListener(screenOffAction, screenOffTimeoutSpinBox.value)
                } else {
                    removeListener(screenOffAction)
                }
            }
        }

        ConfigSpinBox {
            id: screenOffTimeoutSpinBox
            text: "Timeout (minutes)"
            from: 1
            to: 120
            stepSize: 1
            value: screenOffListener ? (screenOffListener.timeout / 60) : 10
            enabled: parent.parent.screenOffListener !== null && parent.parent.screenOffListener !== undefined
            onValueChanged: {
                if (enabled) {
                    setListener(screenOffAction, value)
                }
            }
        }
    }

    ContentSection {
        icon: "power_settings_new"
        title: "Suspend"

        ConfigSwitch {
            checked: suspendListener !== null && suspendListener !== undefined
            onCheckedChanged: {
                if (checked) {
                    setListener(suspendAction, suspendTimeoutSpinBox.value)
                } else {
                    removeListener(suspendAction)
                }
            }
        }

        ConfigSpinBox {
            id: suspendTimeoutSpinBox
            text: "Timeout (minutes)"
            from: 1
            to: 240
            stepSize: 1
            value: suspendListener ? (suspendListener.timeout / 60) : 15
            enabled: parent.parent.suspendListener !== null && parent.parent.suspendListener !== undefined
            onValueChanged: {
                if (enabled) {
                    setListener(suspendAction, value)
                }
            }
        }
    }
}