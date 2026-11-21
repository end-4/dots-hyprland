import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    id: generalPage
    forceWidth: true
    property var startupApps: []
    property var installedApps: []
    property string pickedStartupIcon: ""
    property bool startupGridMode: true
    property string startupSortBy: "status"
    property bool startupSortAsc: false

    readonly property var sortedStartupApps: {
        const arr = (generalPage.startupApps || []).slice();
        const dir = generalPage.startupSortAsc ? 1 : -1;
        arr.sort((a, b) => {
            if (generalPage.startupSortBy === "name") {
                return a.name.localeCompare(b.name) * (generalPage.startupSortAsc ? -1 : 1);
            }
            if (generalPage.startupSortBy === "date") {
                return ((a.mtime ?? 0) - (b.mtime ?? 0)) * dir;
            }
            if (a.enabled !== b.enabled) return (a.enabled ? 1 : -1) * dir;
            return a.name.localeCompare(b.name);
        });
        return arr;
    }

    function refreshStartupApps() {
        startupListProc.running = false;
        startupListProc.running = true;
    }

    Process {
        id: startupListProc
        command: ["python3", Quickshell.shellPath("scripts/startup-apps.py"), "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    generalPage.startupApps = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: installedAppsProc
        command: ["python3", Quickshell.shellPath("scripts/startup-apps.py"), "apps"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    generalPage.installedApps = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Process {
        id: startupActionProc
        onExited: generalPage.refreshStartupApps()
    }

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    ContentSection {
        icon: "volume_up"
        title: Translation.tr("Audio")

        ConfigSwitch {
            buttonIcon: "hearing"
            text: Translation.tr("Earbang protection")
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                Config.options.audio.protection.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Prevents abrupt increments and restricts volume limit")
            }
        }
        ConfigRow {
            enabled: Config.options.audio.protection.enable
            ConfigSpinBox {
                icon: "arrow_warm_up"
                text: Translation.tr("Max allowed increase")
                value: Config.options.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowedIncrease = value;
                }
            }
            ConfigSpinBox {
                icon: "vertical_align_top"
                text: Translation.tr("Volume limit")
                value: Config.options.audio.protection.maxAllowed
                from: 0
                to: 154 // pavucontrol allows up to 153%
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowed = value;
                }
            }
        }
    }

    ContentSection {
        icon: "battery_android_full"
        title: Translation.tr("Battery")

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "warning"
                text: Translation.tr("Low warning")
                value: Config.options.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.low = value;
                }
            }
            ConfigSpinBox {
                icon: "dangerous"
                text: Translation.tr("Critical warning")
                value: Config.options.battery.critical
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.critical = value;
                }
            }
        }
        ConfigRow {
            uniform: false
            Layout.fillWidth: false
            ConfigSwitch {
                buttonIcon: "pause"
                text: Translation.tr("Automatic suspend")
                checked: Config.options.battery.automaticSuspend
                onCheckedChanged: {
                    Config.options.battery.automaticSuspend = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Automatically suspends the system when battery is low")
                }
            }
            ConfigSpinBox {
                enabled: Config.options.battery.automaticSuspend
                text: Translation.tr("at")
                value: Config.options.battery.suspend
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.suspend = value;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "charger"
                text: Translation.tr("Full warning")
                value: Config.options.battery.full
                from: 0
                to: 101
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.full = value;
                }
            }
        }
    }

    ContentSection {
        icon: "language"
        title: Translation.tr("Language")

        ContentSubsection {
            title: Translation.tr("Interface Language")
            tooltip: Translation.tr("Select the language for the user interface.\n\"Auto\" will use your system's locale.")

            StyledComboBox {
                id: languageSelector
                buttonIcon: "language"
                textRole: "displayName"

                model: [
                    {
                        displayName: Translation.tr("Auto (System)"),
                        value: "auto"
                    },
                    ...Translation.allAvailableLanguages.map(lang => {
                        return {
                            displayName: lang,
                            value: lang
                        };
                    })]

                currentIndex: {
                    const index = model.findIndex(item => item.value === Config.options.language.ui);
                    return index !== -1 ? index : 0;
                }

                onActivated: index => {
                    Config.options.language.ui = model[index].value;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Generate translation with Gemini")
            tooltip: Translation.tr("You'll need to enter your Gemini API key first.\nType /key on the sidebar for instructions.")

            ConfigRow {
                MaterialTextArea {
                    id: localeInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Locale code, e.g. fr_FR, de_DE, zh_CN...")
                    text: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                }
                RippleButtonWithIcon {
                    id: generateTranslationBtn
                    Layout.fillHeight: true
                    nerdIcon: ""
                    enabled: !translationProc.running || (translationProc.locale !== localeInput.text.trim())
                    mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
                    onClicked: {
                        translationProc.locale = localeInput.text.trim();
                        translationProc.running = false;
                        translationProc.running = true;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "rocket_launch"
        title: Translation.tr("Startup Apps")

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RippleButton {
                id: installedAppBtn
                Layout.fillWidth: true
                implicitHeight: 40
                buttonRadius: Appearance.rounding.normal
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colSurfaceContainerHigh
                onClicked: installedAppPopup.opened ? installedAppPopup.close() : installedAppPopup.open()
                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    MaterialSymbol {
                        text: "apps"
                        iconSize: 18
                        color: Appearance.m3colors.m3onSurface
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Select installed app...")
                        color: Appearance.m3colors.m3onSurface
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                    MaterialSymbol {
                        text: installedAppPopup.opened ? "expand_less" : "expand_more"
                        iconSize: 20
                        color: Appearance.colors.colSubtext
                    }
                }

                Popup {
                    id: installedAppPopup
                    y: installedAppBtn.height + 6
                    width: installedAppBtn.width
                    height: Math.min(260, Math.max(96, installedAppsGrid.implicitHeight + 20))
                    padding: 10
                    modal: false
                    focus: true
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                    background: Rectangle {
                        radius: Appearance.rounding.normal
                        color: Qt.rgba(Appearance.m3colors.m3surfaceContainerLow.r, Appearance.m3colors.m3surfaceContainerLow.g, Appearance.m3colors.m3surfaceContainerLow.b, 1.0)
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant
                    }

                    contentItem: Flickable {
                        id: installedAppsScroll
                        clip: true
                        contentWidth: width
                        contentHeight: installedAppsGrid.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        GridLayout {
                            id: installedAppsGrid
                            width: installedAppsScroll.width
                            columnSpacing: 8
                            rowSpacing: 8
                            columns: 2

                            Repeater {
                                model: generalPage.installedApps
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 42
                                    radius: Appearance.rounding.normal
                                    color: pickArea.containsMouse ? Appearance.colors.colSurfaceContainerHigh : Appearance.colors.colLayer2
                                    border.width: 1
                                    border.color: Appearance.colors.colOutlineVariant

                                    MouseArea {
                                        id: pickArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            startupNameInput.text = modelData.displayName;
                                            startupCmdInput.text = modelData.exec;
                                            generalPage.pickedStartupIcon = modelData.icon || "";
                                            installedAppPopup.close();
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8
                                        Image {
                                            width: 20
                                            height: 20
                                            sourceSize: Qt.size(20, 20)
                                            source: {
                                                const ic = modelData.icon || "application-x-executable";
                                                if (ic.startsWith("/")) return "file://" + ic;
                                                return Quickshell.iconPath(ic, "application-x-executable");
                                            }
                                            fillMode: Image.PreserveAspectFit
                                        }
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modelData.displayName
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.m3colors.m3onSurface
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RippleButton {
                id: startupSortBtn
                implicitWidth: 40
                implicitHeight: 40
                buttonRadius: Appearance.rounding.normal
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colSurfaceContainerHigh
                onClicked: startupSortPopup.opened ? startupSortPopup.close() : startupSortPopup.open()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "sort"
                    iconSize: 20
                    color: Appearance.m3colors.m3onSurface
                }

                Popup {
                    id: startupSortPopup
                    x: parent.width - width
                    y: parent.height + 6
                    width: 200
                    padding: 6
                    modal: false
                    focus: true
                    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                    background: Rectangle {
                        radius: Appearance.rounding.normal
                        color: Qt.rgba(Appearance.m3colors.m3surfaceContainerLow.r, Appearance.m3colors.m3surfaceContainerLow.g, Appearance.m3colors.m3surfaceContainerLow.b, 1.0)
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant
                    }

                    contentItem: ColumnLayout {
                        spacing: 4
                        Repeater {
                            model: [
                                { id: "name", label: Translation.tr("Name"), icon: "sort_by_alpha" },
                                { id: "date", label: Translation.tr("Date added"), icon: "schedule" },
                                { id: "status", label: Translation.tr("Active status"), icon: "toggle_on" }
                            ]
                            delegate: RippleButton {
                                required property var modelData
                                readonly property bool active: generalPage.startupSortBy === modelData.id
                                Layout.fillWidth: true
                                implicitHeight: 34
                                buttonRadius: Appearance.rounding.small
                                colBackground: active ? Appearance.colors.colPrimaryContainer : "transparent"
                                colBackgroundHover: Appearance.colors.colSurfaceContainerHigh
                                onClicked: {
                                    if (active) {
                                        generalPage.startupSortAsc = !generalPage.startupSortAsc;
                                    } else {
                                        generalPage.startupSortBy = modelData.id;
                                        generalPage.startupSortAsc = (modelData.id === "name");
                                    }
                                    startupSortPopup.close();
                                }
                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8
                                    MaterialSymbol {
                                        text: modelData.icon
                                        iconSize: 16
                                        color: active ? Appearance.colors.colPrimary : Appearance.m3colors.m3onSurface
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: active ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface
                                    }
                                    MaterialSymbol {
                                        visible: active
                                        text: generalPage.startupSortAsc ? "arrow_upward" : "arrow_downward"
                                        iconSize: 14
                                        color: Appearance.colors.colPrimary
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RippleButton {
                implicitWidth: 40
                implicitHeight: 40
                buttonRadius: Appearance.rounding.normal
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colSurfaceContainerHigh
                onClicked: generalPage.startupGridMode = !generalPage.startupGridMode
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: generalPage.startupGridMode ? "grid_view" : "view_headline"
                    iconSize: 20
                    color: Appearance.m3colors.m3onSurface
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialTextArea {
                id: startupNameInput
                Layout.preferredWidth: 140
                placeholderText: Translation.tr("App name")
            }

            MaterialTextArea {
                id: startupCmdInput
                Layout.fillWidth: true
                placeholderText: Translation.tr("Command or path")
            }

            RippleButton {
                id: addStartupBtn
                implicitWidth: addStartupTxt.implicitWidth + 24
                implicitHeight: 38
                buttonRadius: Appearance.rounding.full
                colBackground: enabled ? Appearance.colors.colPrimary : Appearance.colors.colSurfaceContainerHigh
                colBackgroundHover: Appearance.colors.colPrimaryHover
                enabled: startupNameInput.text.trim() !== "" && startupCmdInput.text.trim() !== ""
                onClicked: {
                    startupActionProc.command = [
                        "python3",
                        Quickshell.shellPath("scripts/startup-apps.py"),
                        "add",
                        startupNameInput.text.trim(),
                        startupCmdInput.text.trim(),
                        generalPage.pickedStartupIcon
                    ];
                    startupActionProc.running = false;
                    startupActionProc.running = true;
                    startupNameInput.text = "";
                    startupCmdInput.text = "";
                    generalPage.pickedStartupIcon = "";
                }
                contentItem: StyledText {
                    id: addStartupTxt
                    anchors.centerIn: parent
                    text: Translation.tr("Add")
                    color: addStartupBtn.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            opacity: 0.65
        }

        Flickable {
            id: startupScroll
            Layout.fillWidth: true
            implicitHeight: Math.min(Math.max(88, startupGrid.implicitHeight + 4), 260)
            contentWidth: width
            contentHeight: startupGrid.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            GridLayout {
                id: startupGrid
                width: startupScroll.width
                columnSpacing: 8
                rowSpacing: 8
                columns: generalPage.startupGridMode ? 2 : 1

                Repeater {
                    model: generalPage.sortedStartupApps
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 48
                        radius: Appearance.rounding.normal
                        color: Appearance.colors.colLayer2
                        border.width: 1
                        border.color: modelData.enabled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colOutlineVariant

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 10

                            Image {
                                width: 22
                                height: 22
                                sourceSize: Qt.size(22, 22)
                                source: {
                                    const ic = modelData.icon || "application-x-executable";
                                    if (ic.startsWith("/")) return "file://" + ic;
                                    return Quickshell.iconPath(ic, "application-x-executable");
                                }
                                fillMode: Image.PreserveAspectFit
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.name
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: Appearance.m3colors.m3onSurface
                                elide: Text.ElideRight
                            }

                            RippleButton {
                                visible: modelData.removable
                                implicitWidth: 26
                                implicitHeight: 26
                                buttonRadius: Appearance.rounding.full
                                colBackground: "transparent"
                                colBackgroundHover: Appearance.colors.colSurfaceContainerHigh
                                onClicked: {
                                    startupActionProc.command = [
                                        "python3",
                                        Quickshell.shellPath("scripts/startup-apps.py"),
                                        "remove",
                                        modelData.id
                                    ];
                                    startupActionProc.running = false;
                                    startupActionProc.running = true;
                                }
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "delete"
                                    iconSize: 16
                                    color: Appearance.colors.colError
                                }
                            }

                            StyledSwitch {
                                checked: modelData.enabled
                                onClicked: {
                                    startupActionProc.command = [
                                        "python3",
                                        Quickshell.shellPath("scripts/startup-apps.py"),
                                        "toggle",
                                        modelData.id,
                                        checked ? "1" : "0"
                                    ];
                                    startupActionProc.running = false;
                                    startupActionProc.running = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
            opacity: 0.65
        }

        StyledText {
            visible: generalPage.startupApps.length === 0
            text: Translation.tr("No startup apps found")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }

    ContentSection {
        icon: "rule"
        title: Translation.tr("Policies")

        ConfigRow {

            // AI policy
            ColumnLayout {
                ContentSubsectionLabel {
                    text: Translation.tr("AI")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.ai
                    onSelected: newValue => {
                        Config.options.policies.ai = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Local only"),
                            icon: "sync_saved_locally",
                            value: 2
                        }
                    ]
                }
            }

            // Weeb policy
            ColumnLayout {

                ContentSubsectionLabel {
                    text: Translation.tr("Weeb")
                }

                ConfigSelectionArray {
                    currentValue: Config.options.policies.weeb
                    onSelected: newValue => {
                        Config.options.policies.weeb = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Closet"),
                            icon: "ev_shadow",
                            value: 2
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "notification_sound"
        title: Translation.tr("Sounds")
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "battery_android_full"
                text: Translation.tr("Battery")
                checked: Config.options.sounds.battery
                onCheckedChanged: {
                    Config.options.sounds.battery = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "av_timer"
                text: Translation.tr("Pomodoro")
                checked: Config.options.sounds.pomodoro
                onCheckedChanged: {
                    Config.options.sounds.pomodoro = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "nest_clock_farsight_analog"
        title: Translation.tr("Time")

        ConfigSwitch {
            buttonIcon: "pace"
            text: Translation.tr("Second precision")
            checked: Config.options.time.secondPrecision
            onCheckedChanged: {
                Config.options.time.secondPrecision = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enable if you want clocks to show seconds accurately")
            }
        }

        ContentSubsection {
            title: Translation.tr("Format")
            tooltip: ""

            ConfigSelectionArray {
                currentValue: Config.options.time.format
                onSelected: newValue => {
                    if (newValue === "hh:mm") {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    } else {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    }

                    Config.options.time.format = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("24h"),
                        value: "hh:mm"
                    },
                    {
                        displayName: Translation.tr("12h am/pm"),
                        value: "h:mm ap"
                    },
                    {
                        displayName: Translation.tr("12h AM/PM"),
                        value: "h:mm AP"
                    },
                ]
            }
        }
    }

    ContentSection {
        icon: "work_alert"
        title: Translation.tr("Work safety")

        ConfigSwitch {
            buttonIcon: "assignment"
            text: Translation.tr("Hide clipboard images copied from sussy sources")
            checked: Config.options.workSafety.enable.clipboard
            onCheckedChanged: {
                Config.options.workSafety.enable.clipboard = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "wallpaper"
            text: Translation.tr("Hide sussy/anime wallpapers")
            checked: Config.options.workSafety.enable.wallpaper
            onCheckedChanged: {
                Config.options.workSafety.enable.wallpaper = checked;
            }
        }
    }
}
