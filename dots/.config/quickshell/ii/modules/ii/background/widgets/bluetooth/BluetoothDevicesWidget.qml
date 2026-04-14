import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "bluetooth"

    readonly property real widgetOpacity: Math.max(0.2, Math.min(1, Number(configEntry?.opacity ?? 0.92)))
    readonly property string listOrientation: configEntry?.listOrientation === "vertical" ? "vertical" : "horizontal"
    readonly property bool verticalList: listOrientation === "vertical"
    readonly property int refreshIntervalMinutes: Math.max(1, Number(configEntry?.refreshIntervalMinutes ?? 1))
    readonly property int refreshIntervalMs: refreshIntervalMinutes * 60 * 1000
    readonly property int maxVisibleDevices: Math.max(1, Number(configEntry?.maxVisibleDevices ?? 8))

    property var deviceSnapshot: []
    property string lastRefresh: "--:--"

    readonly property int chipWidth: 108
    readonly property int chipSpacing: 12
    readonly property int cardPadding: 18
    readonly property int listPadding: 8
    readonly property int shownCount: Math.max(1, deviceSnapshot.length)
    readonly property int horizontalListWidth: (deviceSnapshot.length === 0) ? 220 : (shownCount * chipWidth + Math.max(0, shownCount - 1) * chipSpacing + listPadding * 2)
    implicitWidth: verticalList ? 390 : Math.max(260, Math.min(980, horizontalListWidth + cardPadding * 2))
    implicitHeight: verticalList ? Math.max(220, Math.min(760, 110 + shownCount * 102)) : 248

    readonly property color cardBackgroundColor: ColorUtils.applyAlpha(Appearance.colors.colLayer1, widgetOpacity)
    readonly property color cardBorderColor: ColorUtils.applyAlpha(Appearance.colors.colOutline, 0.55)
    readonly property color tileBackgroundColor: ColorUtils.applyAlpha(Appearance.colors.colLayer2, Math.min(1, widgetOpacity + 0.06))
    readonly property color tileBorderColor: ColorUtils.applyAlpha(Appearance.colors.colOutlineVariant, 0.8)
    readonly property color textPrimaryColor: Appearance.colors.colOnLayer2
    readonly property color textSecondaryColor: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.78)
    readonly property color ringHighColor: ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colOnPrimary, 0.86)
    readonly property color ringMediumColor: ColorUtils.mix(Appearance.colors.colTertiary, Appearance.colors.colOnTertiary, 0.86)
    readonly property color ringLowColor: ColorUtils.mix(Appearance.colors.colError, Appearance.colors.colOnError, 0.90)

    function batteryKnown(device) {
        return device?.batteryAvailable ?? false;
    }

    function batteryLevel(device) {
        if (!batteryKnown(device))
            return 0;
        return Math.max(0, Math.min(1, Number(device?.battery ?? 0)));
    }

    function ringColor(device) {
        const level = batteryLevel(device);
        if (!batteryKnown(device))
            return Appearance.colors.colOnLayer2;
        if (level < 0.20)
            return root.ringLowColor;
        if (level < 0.40)
            return root.ringMediumColor;
        return root.ringHighColor;
    }

    function deviceIcon(device) {
        return Icons.getBluetoothDeviceMaterialSymbol(device?.icon || "");
    }

    function refreshDevices() {
        const devices = BluetoothStatus.connectedDevices || [];
        root.deviceSnapshot = devices.slice(0, root.maxVisibleDevices);
        root.lastRefresh = DateTime.time;
    }

    onMaxVisibleDevicesChanged: refreshDevices()

    Connections {
        target: BluetoothStatus

        function onConnectedDevicesChanged() {
            root.refreshDevices();
        }
    }

    Timer {
        id: refreshTimer
        interval: root.refreshIntervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshDevices()
    }

    StyledDropShadow {
        target: backgroundRect
    }

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        radius: Appearance.rounding.large
        color: root.cardBackgroundColor
        border.width: 1
        border.color: root.cardBorderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: ColorUtils.applyAlpha(Appearance.colors.colLayer2, 0.92)
                    border.width: 1
                    border.color: root.tileBorderColor

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "devices"
                        iconSize: 19
                        color: root.textPrimaryColor
                    }
                }

                StyledText {
                    text: Translation.tr("Devices")
                    color: root.textPrimaryColor
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                }

                StyledText {
                    text: root.lastRefresh
                    color: root.textSecondaryColor
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: ColorUtils.applyAlpha(Appearance.colors.colLayer2, 0.34)
                radius: Appearance.rounding.normal

                StyledListView {
                    id: devicesList
                    anchors.fill: parent
                    anchors.margins: root.listPadding
                    clip: true
                    spacing: root.verticalList ? 8 : root.chipSpacing
                    animateAppearance: false
                    orientation: root.verticalList ? ListView.Vertical : ListView.Horizontal
                    boundsBehavior: Flickable.StopAtBounds

                    model: root.deviceSnapshot

                    delegate: root.verticalList ? verticalDeviceDelegate : horizontalDeviceDelegate
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: root.deviceSnapshot.length === 0
                    text: Translation.tr("No connected Bluetooth devices")
                    color: root.textSecondaryColor
                    font.pixelSize: Appearance.font.pixelSize.smallie
                }
            }
        }
    }

    component DeviceRing: Item {
        id: ring
        required property var device

        readonly property bool hasBattery: root.batteryKnown(device)
        readonly property real progressLevel: root.batteryLevel(device)
        readonly property color thresholdColor: root.ringColor(device)
        readonly property real arcStartAngle: 126
        readonly property real arcSweep: 288

        property real blinkOpacity: 1

        function withAlpha(color, alphaValue) {
            const c = Qt.color(color);
            return Qt.rgba(c.r, c.g, c.b, Math.max(0, Math.min(1, alphaValue)));
        }

        onProgressLevelChanged: {
            if (progressLevel >= 0.05)
                blinkOpacity = 1;
        }

        width: 76
        height: 98

        SequentialAnimation on blinkOpacity {
            running: ring.hasBattery && ring.progressLevel < 0.05
            loops: Animation.Infinite
            NumberAnimation {
                from: 1
                to: 0.25
                duration: 360
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                from: 0.25
                to: 1
                duration: 360
                easing.type: Easing.InOutQuad
            }
        }

        Item {
            id: ringCanvas
            width: 76
            height: 76
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, 0.22)
                    strokeWidth: 6
                    capStyle: ShapePath.RoundCap
                    fillColor: "transparent"
                    PathAngleArc {
                        centerX: ringCanvas.width / 2
                        centerY: ringCanvas.height / 2
                        radiusX: ringCanvas.width / 2 - 5
                        radiusY: ringCanvas.height / 2 - 5
                        startAngle: ring.arcStartAngle
                        sweepAngle: ring.arcSweep
                    }
                }

                ShapePath {
                    strokeColor: ring.withAlpha(ring.thresholdColor, ring.blinkOpacity)
                    strokeWidth: 6
                    capStyle: ShapePath.RoundCap
                    fillColor: "transparent"
                    PathAngleArc {
                        centerX: ringCanvas.width / 2
                        centerY: ringCanvas.height / 2
                        radiusX: ringCanvas.width / 2 - 5
                        radiusY: ringCanvas.height / 2 - 5
                        startAngle: ring.arcStartAngle
                        sweepAngle: ring.hasBattery ? ring.arcSweep * ring.progressLevel : 0
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 48
                height: 48
                radius: 24
                color: ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.95)
                border.width: 1
                border.color: root.tileBorderColor

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.deviceIcon(ring.device)
                    iconSize: 23
                    color: root.textPrimaryColor
                }
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: ring.hasBattery ? Math.round(ring.progressLevel * 100) + "%" : "--"
            color: ring.hasBattery ? ring.withAlpha(ring.thresholdColor, ring.blinkOpacity) : root.textSecondaryColor
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
        }
    }

    component HorizontalDeviceDelegate: Rectangle {
        id: chip
        required property var modelData
        readonly property var device: modelData

        width: root.chipWidth
        height: 132
        radius: Appearance.rounding.normal
        color: root.tileBackgroundColor
        border.width: 1
        border.color: root.tileBorderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            DeviceRing {
                Layout.alignment: Qt.AlignHCenter
                device: chip.device
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: chip.device?.name || Translation.tr("Unknown")
                textFormat: Text.PlainText
                color: root.textPrimaryColor
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
        }
    }

    component VerticalDeviceDelegate: Rectangle {
        id: rowCard
        required property var modelData
        readonly property var device: modelData

        width: ListView.view ? ListView.view.width : 320
        height: 114
        radius: Appearance.rounding.normal
        color: root.tileBackgroundColor
        border.width: 1
        border.color: root.tileBorderColor

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            DeviceRing {
                Layout.preferredWidth: 76
                Layout.preferredHeight: 98
                device: rowCard.device
            }

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                text: rowCard.device?.name || Translation.tr("Unknown")
                textFormat: Text.PlainText
                color: root.textPrimaryColor
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
            }
        }
    }

    Component {
        id: horizontalDeviceDelegate
        HorizontalDeviceDelegate {}
    }

    Component {
        id: verticalDeviceDelegate
        VerticalDeviceDelegate {}
    }
}
