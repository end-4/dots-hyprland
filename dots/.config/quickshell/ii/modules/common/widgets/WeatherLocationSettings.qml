pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Shared weather settings: location (automatic, or a searched city), units and polling interval.
// The bar weather and the background weather widget read the same config (bar.weather),
// so this one component is used in Settings -> Bar, Background and Services.
ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 12

    readonly property var cfg: Config.options.bar.weather

    property string query: ""
    property var results: []
    property string searchStatus: "" // "", "searching", "empty", "error"
    property bool applying: false

    readonly property string uiLang: {
        const ui = Config.options.language?.ui ?? "auto";
        return (ui === "auto" ? Qt.locale().name : ui).split(/[_-]/)[0];
    }

    function search(text) {
        const q = text.trim();
        if (q.length < 2) {
            root.results = [];
            root.searchStatus = "";
            return;
        }
        root.searchStatus = "searching";
        searchProc.running = false;
        searchProc.command = ["curl", "-s", "-m", "8", `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(q)}&count=6&language=${root.uiLang}&format=json`];
        searchProc.running = true;
    }

    function labelOf(place) {
        return [place.name, place.admin1, place.country].filter((x, i, a) => x && a.indexOf(x) === i).join(", ");
    }

    function pick(place) {
        root.applying = true;
        root.cfg.city = `${place.latitude},${place.longitude}`;
        root.cfg.label = root.labelOf(place);
        root.cfg.enableGPS = false;
        root.results = [];
        root.searchStatus = "";
        searchInput.text = "";
        root.applying = false;
    }

    Timer {
        id: debounce
        interval: 450
        onTriggered: root.search(root.query)
    }

    Process {
        id: searchProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.results = JSON.parse(text).results ?? [];
                    root.searchStatus = root.results.length > 0 ? "" : "empty";
                } catch (e) {
                    root.results = [];
                    root.searchStatus = "error";
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                root.results = [];
                root.searchStatus = "error";
            }
        }
    }

    // ---- Location
    ContentSubsection {
        title: Translation.tr("Location")
        tooltip: Translation.tr("Pick \"Automatic\" to detect your location, or choose a place by hand.")

        ConfigSelectionArray {
            Layout.fillWidth: false
            currentValue: root.cfg.enableGPS ? "gps" : "manual"
            onSelected: newValue => {
                root.cfg.enableGPS = newValue === "gps";
            }
            options: [
                {
                    displayName: Translation.tr("Automatic"),
                    icon: "assistant_navigation",
                    value: "gps"
                },
                {
                    displayName: Translation.tr("Choose manually"),
                    icon: "edit_location_alt",
                    value: "manual"
                }
            ]
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12
        visible: !root.cfg.enableGPS

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            text: root.cfg.label.length > 0 ? Translation.tr("Selected: %1").arg(root.cfg.label) : (root.cfg.city.length > 0 ? Translation.tr("Selected: %1").arg(root.cfg.city) : Translation.tr("No place selected yet"))
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
            elide: Text.ElideRight
        }

        ContentSubsection {
            title: Translation.tr("Search for a place")

            MaterialTextArea {
                id: searchInput
                Layout.fillWidth: true
                placeholderText: Translation.tr("Search for a city")
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    if (root.applying)
                        return;
                    root.query = text;
                    debounce.restart();
                }
            }

            StyledText {
                visible: root.searchStatus !== ""
                Layout.fillWidth: true
                Layout.leftMargin: 8
                text: root.searchStatus === "searching" ? Translation.tr("Searching...") : root.searchStatus === "empty" ? Translation.tr("No matching city found") : Translation.tr("Could not search cities. Check your internet connection.")
                color: root.searchStatus === "error" ? Appearance.colors.colError : Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
            }

            Repeater {
                model: root.results
                delegate: RippleButtonWithIcon {
                    id: resultButton
                    required property var modelData
                    Layout.fillWidth: true
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "location_on"
                    mainText: root.labelOf(resultButton.modelData)
                    onClicked: root.pick(resultButton.modelData)
                }
            }
        }
    }

    // ---- Units
    ContentSubsection {
        title: Translation.tr("Temperature unit")

        ConfigSelectionArray {
            Layout.fillWidth: false
            currentValue: root.cfg.useUSCS ? "f" : "c"
            onSelected: newValue => {
                root.cfg.useUSCS = newValue === "f";
            }
            options: [
                {
                    displayName: Translation.tr("Celsius (°C)"),
                    icon: "device_thermostat",
                    value: "c"
                },
                {
                    displayName: Translation.tr("Fahrenheit (°F)"),
                    icon: "thermometer",
                    value: "f"
                }
            ]
        }
    }

    // ---- Refresh
    ContentSubsection {
        title: Translation.tr("Refresh")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (m)")
            value: root.cfg.fetchInterval
            from: 5
            to: 50
            stepSize: 5
            onValueChanged: {
                root.cfg.fetchInterval = value;
            }
        }
    }
}
