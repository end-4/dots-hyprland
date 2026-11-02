import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

Item {
    id: root
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)

    // Más reciente primero (focusHistoryID menor = usada hace menos)
    readonly property var minimized: HyprlandData.windowList
        .filter(w => w.workspace?.name === "special:minimized")
        .sort((a, b) => (a.focusHistoryID ?? 0) - (b.focusHistoryID ?? 0))

    readonly property real btnSize: 30
    readonly property real gap: 4
    readonly property int fit: Math.max(0, Math.floor((width + gap) / (btnSize + gap)))
    readonly property bool overflow: minimized.length > fit
    readonly property int shown: overflow ? Math.max(0, fit - 1) : minimized.length

    property bool popupOpen: false
    onOverflowChanged: if (!overflow) popupOpen = false

    implicitWidth: 0   // BarContent ya le da fillWidth; así no empuja al resto

    function restore(address) {
        const ws = HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id
        if (ws === undefined) return
        Quickshell.execDetached(["hyprctl", "dispatch",
            `hl.dsp.window.move({ workspace = ${ws}, follow = false, window = "address:${address}" })`])
    }

    // Icono de la app; si el tema no lo tiene, insignia con la inicial
    component AppIcon: Item {
        id: icon
        required property var win
        property real size: 19.5
        implicitWidth: size
        implicitHeight: size
        readonly property string src: Quickshell.iconPath(AppSearch.guessIcon(win.class), true)

        IconImage {
            anchors.fill: parent
            visible: icon.src !== ""
            source: icon.src
        }
        Rectangle {
            anchors.fill: parent
            visible: icon.src === ""
            radius: Appearance.rounding.full
            color: Appearance.colors.colSecondaryContainer
            StyledText {
                anchors.centerIn: parent
                text: (icon.win.class || "?").charAt(0).toUpperCase()
                font.pixelSize: icon.size * 0.55
                color: Appearance.colors.colOnLayer0
            }
        }
    }

    // Absorbe el click izquierdo en el hueco (evita el toggle del sidebar)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
    }

    // ScriptModel compara por address: no recrea delegados en cada evento de Hyprland
    ScriptModel { id: shownModel; objectProp: "address"; values: root.minimized.slice(0, root.shown) }
    ScriptModel { id: restModel;  objectProp: "address"; values: root.minimized.slice(root.shown) }

    RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: root.gap

        Repeater {
            model: shownModel
            delegate: RippleButton {
                required property var modelData
                implicitWidth: root.btnSize
                implicitHeight: root.btnSize
                buttonRadius: Appearance.rounding.full
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colLayer1Active
                onPressed: root.restore(modelData.address)

                AppIcon { anchors.centerIn: parent; win: modelData }
            }
        }

        RippleButton {   // botón "+N": abre/cierra el popup
            id: chip
            visible: root.overflow
            implicitWidth: Math.max(root.btnSize, chipLabel.implicitWidth + 16)
            implicitHeight: root.btnSize
            buttonRadius: Appearance.rounding.full
            colBackgroundHover: Appearance.colors.colLayer1Hover
            colRipple: Appearance.colors.colLayer1Active
            colBackgroundToggled: Appearance.colors.colSecondaryContainer
            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
            colRippleToggled: Appearance.colors.colSecondaryContainerActive
            toggled: root.popupOpen
            onPressed: root.popupOpen = !root.popupOpen

            StyledText {
                id: chipLabel
                anchors.centerIn: parent
                text: "+" + restModel.values.length
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer0
            }

            // hoverTarget de StyledPopup: aquí lo gobierna el estado de click, no el puntero
            Item {
                id: popupAnchor
                anchors.fill: parent
                readonly property bool containsMouse: root.popupOpen
                readonly property bool hovered: root.popupOpen   // por si StyledPopup usa este nombre
            }
        }
    }

    StyledPopup {
        hoverTarget: popupAnchor

        Item {
            id: popupContent
            implicitWidth: 250
            implicitHeight: list.implicitHeight

            ColumnLayout {
                id: list
                anchors.fill: parent
                spacing: 2

                Repeater {
                    model: restModel
                    delegate: RippleButton {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 34
                        buttonRadius: Appearance.rounding.full
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active
                        onPressed: root.restore(modelData.address)

                        RowLayout {
                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                            spacing: 8
                            AppIcon { win: modelData; size: 20; Layout.alignment: Qt.AlignVCenter }
                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.title || modelData.class
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
            }
        }
    }

    // Click fuera => cierra. La barra y el popup cuentan como "dentro"
    HyprlandFocusGrab {
        readonly property var popupWindow: popupContent.QsWindow.window
        windows: [root.QsWindow.window, popupWindow].filter(w => w)
        active: root.popupOpen && !!popupWindow
        onCleared: root.popupOpen = false
    }
}
