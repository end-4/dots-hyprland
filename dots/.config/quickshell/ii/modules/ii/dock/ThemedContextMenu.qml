pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * Reusable themed context menu.
 * - Background follows the Material 3 theme (dark/light variants).
 * - Scales and fades in when shown.
 * - Items are supplied via a model of { icon, text, onClicked } roles.
 */
Item {
    id: root
    property bool open: false
    property point menuPosition: Qt.point(0, 0)
    property var model: []
    property int menuWidth: 200

    signal itemClicked(int index)

    // ── Themed colors (m3 surface containers adapt to dark/light) ──
    readonly property color menuBackground: Appearance.m3colors.m3surfaceContainerHigh
    readonly property color menuBorder: ColorUtils.transparentize(Appearance.m3colors.m3outlineVariant, 0.6)
    readonly property color itemText: Appearance.m3colors.m3onSurface
    readonly property color itemHover: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerHighest, 0.6)
    readonly property color itemRipple: ColorUtils.transparentize(Appearance.m3colors.m3primary, 0.3)
    readonly property color itemBackground: "transparent"

    // ── Animation state ──
    property real animScale: open ? 1.0 : 0.9
    property real animOpacity: open ? 1.0 : 0.0

    Behavior on animScale {
        NumberAnimation {
            duration: open ? 150 : 100
            easing.type: Easing.OutCubic
        }
    }
    Behavior on animOpacity {
        NumberAnimation {
            duration: open ? 120 : 80
            easing.type: Easing.OutCubic
        }
    }

    visible: root.open || root.animOpacity > 0

    // NOTE: no full-area click catcher here on purpose. The host window
    // (full-screen menu window) handles outside clicks, so this component
    // never intercepts events meant for the trigger button underneath.

    StyledRectangularShadow {
        target: menuRect
        opacity: root.animOpacity
    }

    Rectangle {
        id: menuRect
        x: Math.min(root.menuPosition.x, parent.width - width - 10)
        y: Math.min(root.menuPosition.y, parent.height - height - 10)
        width: root.menuWidth
        height: menuColumn.implicitHeight + 16
        radius: Appearance.rounding.normal
        color: root.menuBackground
        border.width: 1
        border.color: root.menuBorder
        scale: root.animScale
        opacity: root.animOpacity
        transformOrigin: Item.TopLeft

        ColumnLayout {
            id: menuColumn
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Repeater {
                model: root.model

                // ── Separator ──
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    visible: (modelData.icon ?? "") === "separator"
                    color: root.menuBorder
                }

                // ── Regular item ──
                RippleButton {
                    required property var modelData
                    required property int index
                    visible: (modelData.icon ?? "") !== "separator"
                    Layout.fillWidth: true
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    colBackground: root.itemBackground
                    colBackgroundHover: root.itemHover
                    colRipple: root.itemRipple

                    onClicked: {
                        if (modelData.onClicked) modelData.onClicked();
                        // NOTE: do NOT write root.open here — it may be bound by
                        // the host (e.g. `open: host.menuOpen`), and assigning a
                        // bound property permanently breaks the binding.
                        // The host listens to itemClicked and closes itself.
                        root.itemClicked(model.index);
                    }

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: (modelData.icon ?? "") !== "" ? 12 : 16
                        anchors.rightMargin: 12
                        spacing: 12

                        MaterialSymbol {
                            visible: (modelData.icon ?? "") !== ""
                            text: modelData.icon ?? ""
                            iconSize: Appearance.font.pixelSize.normal
                            color: root.itemText
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.text ?? ""
                            font.pixelSize: modelData.textBold
                                ? Appearance.font.pixelSize.smaller
                                : Appearance.font.pixelSize.small
                            font.bold: modelData.textBold ?? false
                            color: root.itemText
                        }
                    }
                }
            }
        }
    }
}
