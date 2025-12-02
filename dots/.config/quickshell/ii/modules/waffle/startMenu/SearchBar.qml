pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

FooterRectangle {
    id: root

    property bool searching: text.length > 0
    property alias text: searchInput.text

    Component.onCompleted: searchInput.forceActiveFocus()

    focus: true
    color: searching ? Looks.colors.bgPanelBody : Looks.colors.bgPanelFooter

    implicitWidth: 832 // TODO: Make sizes naturally inferred
    implicitHeight: 63

    Rectangle {
        id: outline
        anchors {
            fill: parent
            leftMargin: 32
            rightMargin: 32
            topMargin: 16
            bottomMargin: 15
        }
        color: "transparent"
        radius: height / 2
        border.width: 1
        border.color: Looks.colors.bg2Border
    }

    Rectangle {
        id: searchInputBg
        anchors.fill: outline
        anchors.margins: 1
        radius: height / 2
        color: Looks.colors.inputBg

        RowLayout {
            anchors.fill: parent
            spacing: 11

            WAppIcon {
                Layout.leftMargin: 14
                iconName: "system-search-checked"
                separateLightDark: true
                implicitSize: 18
            }

            WTextInput {
                id: searchInput
                focus: true
                Layout.fillWidth: true

                WText {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    color: Looks.colors.accentUnfocused
                    text: Translation.tr("Search for apps") // should also have "", settings, and documents" but we don't have those
                    visible: searchInput.text.length === 0
                    font.pixelSize: Looks.font.pixelSize.large
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        acceptedButtons: Qt.NoButton
    }
}
