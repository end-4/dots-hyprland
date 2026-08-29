pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    readonly property bool active: Tailscale.exitNodeActive
    readonly property bool menuOpen: menuLoader.active

    function openMenu() {
        Tailscale.refresh();
        menuLoader.active = true;
    }
    function closeMenu() {
        focusGrab.active = false;
        menuLoader.active = false;
    }
    function toggleMenu() {
        if (menuLoader.active)
            closeMenu();
        else
            openMenu();
    }

    CircleUtilButton {
        id: button
        anchors.centerIn: parent
        toggled: root.menuOpen
        onClicked: root.toggleMenu()

        MaterialSymbol {
            horizontalAlignment: Qt.AlignHCenter
            fill: root.active ? 1 : 0
            text: !Tailscale.running ? "vpn_key_off" : root.active ? "vpn_lock" : "vpn_key"
            iconSize: Appearance.font.pixelSize.large
            color: root.active ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2

            StyledToolTip {
                extraVisibleCondition: button.hovered && !root.menuOpen
                text: !Tailscale.running ? Translation.tr("Tailscale off") : root.active ? Translation.tr("Exit node: %1").arg(Tailscale.currentExitNodeName) : Translation.tr("No exit node")
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: false
        windows: [menuLoader.item]
        onCleared: root.closeMenu()
    }

    // A selectable row: radio state + icon + label/sublabel + online dot.
    component ExitNodeRow: RippleButton {
        id: rowButton
        property bool selected: false
        property string label: ""
        property string sublabel: ""
        property bool online: true
        property string symbol: "lan"

        Layout.fillWidth: true
        implicitHeight: 40
        buttonRadius: Appearance.rounding.verysmall
        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1, 1)

        contentItem: RowLayout {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
                leftMargin: 8
                rightMargin: 10
            }
            spacing: 8

            MaterialSymbol {
                iconSize: 20
                text: rowButton.selected ? "radio_button_checked" : "radio_button_unchecked"
                color: rowButton.selected ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
            }

            MaterialSymbol {
                iconSize: 18
                fill: rowButton.selected ? 1 : 0
                text: rowButton.symbol
                color: Appearance.colors.colOnLayer0
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: rowButton.label
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: rowButton.sublabel.length > 0
                    elide: Text.ElideRight
                    text: rowButton.sublabel
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }

            Rectangle {
                visible: rowButton.sublabel.length > 0
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: rowButton.online ? Appearance.colors.colOnLayer0 : Appearance.colors.colSubtext
                opacity: rowButton.online ? 1 : 0.35
            }
        }
    }

    Loader {
        id: menuLoader
        active: false

        sourceComponent: PopupWindow {
            id: menuWindow
            color: "transparent"
            visible: true

            readonly property real elevation: Appearance.sizes.elevationMargin

            anchor {
                window: root.QsWindow.window
                item: root
                gravity: (!Config.options.bar.vertical && !Config.options.bar.bottom) ? Edges.Bottom : Edges.Top
                edges: (!Config.options.bar.vertical && !Config.options.bar.bottom) ? Edges.Bottom : Edges.Top
            }

            implicitWidth: menuBackground.implicitWidth + elevation * 2
            implicitHeight: menuBackground.implicitHeight + elevation * 2

            Component.onCompleted: focusGrab.active = true

            StyledRectangularShadow {
                target: menuBackground
            }

            Rectangle {
                id: menuBackground
                readonly property real padding: 6
                anchors.centerIn: parent
                implicitWidth: Math.max(240, contentColumn.implicitWidth + padding * 2)
                implicitHeight: contentColumn.implicitHeight + padding * 2
                color: Appearance.colors.colLayer0
                radius: Appearance.rounding.small
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                ColumnLayout {
                    id: contentColumn
                    anchors.centerIn: parent
                    width: menuBackground.width - menuBackground.padding * 2
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 8
                        Layout.bottomMargin: 4
                        spacing: 8

                        MaterialSymbol {
                            iconSize: 20
                            fill: 1
                            text: "vpn_lock"
                            color: Appearance.colors.colOnLayer0
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Exit node")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                        }
                        RippleButton {
                            implicitWidth: 26
                            implicitHeight: 26
                            buttonRadius: Appearance.rounding.full
                            releaseAction: () => Tailscale.refresh()
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                iconSize: 18
                                text: "refresh"
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledToolTip {
                                text: Translation.tr("Refresh")
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Appearance.colors.colLayer0Border
                    }

                    ExitNodeRow {
                        selected: !Tailscale.exitNodeActive
                        label: Translation.tr("None (direct)")
                        symbol: "public_off"
                        releaseAction: () => {
                            Tailscale.clearExitNode();
                            root.closeMenu();
                        }
                    }

                    Repeater {
                        model: Tailscale.exitNodes
                        delegate: ExitNodeRow {
                            required property var modelData
                            selected: modelData.selected
                            label: modelData.name
                            sublabel: modelData.ip
                            online: modelData.online
                            symbol: "lan"
                            releaseAction: () => {
                                Tailscale.setExitNode(modelData.ip);
                                root.closeMenu();
                            }
                        }
                    }

                    StyledText {
                        visible: Tailscale.exitNodes.length === 0
                        Layout.fillWidth: true
                        Layout.margins: 8
                        wrapMode: Text.WordWrap
                        text: Tailscale.available ? Translation.tr("No exit nodes available") : Tailscale.lastError.length > 0 ? Translation.tr("Unavailable: %1").arg(Tailscale.lastError) : Translation.tr("Tailscale unavailable")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }
        }
    }
}
