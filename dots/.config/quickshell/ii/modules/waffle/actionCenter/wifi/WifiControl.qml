import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

Item {
    id: root
    implicitWidth: 360
    implicitHeight: 352

    Component.onCompleted: {
        Network.rescanWifi();
    }

    PageColumn {
        anchors.fill: parent

        BodyRectangle {
            implicitHeight: 400
            implicitWidth: 50

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                ColumnLayout {
                    implicitHeight: headerRow.implicitHeight
                    Layout.fillWidth: true
                    spacing: 0
                    HeaderRow {
                        id: headerRow
                        Layout.fillWidth: true
                        title: qsTr("Wi-Fi")
                    }
                    FadeLoader {
                        Layout.leftMargin: -4
                        Layout.rightMargin: -4
                        Layout.fillWidth: true
                        shown: Network.wifiScanning
                        sourceComponent: StyledIndeterminateProgressBar {
                            id: progressBar
                            implicitHeight: 3
                            background: null
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: progressBar.width
                                    height: progressBar.height
                                    radius: progressBar.height / 2
                                }
                            }
                        }
                    }
                }

                StyledListView {
                    id: listView
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    animateAppearance: false

                    contentHeight: contentLayout.implicitHeight
                    contentWidth: width
                    clip: true
                    spacing: 4

                    model: ScriptModel {
                        values: Network.friendlyWifiNetworks
                    }
                    delegate: WWifiNetworkItem {
                        required property WifiAccessPoint modelData
                        wifiNetwork: modelData
                        width: ListView.view.width
                    }
                }
            }
        }

        Separator {}

        FooterRectangle {
            WButton {
                id: moreSettingsButton
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                }
                inset: 0
                implicitHeight: 40
                implicitWidth: contentItem.implicitWidth + 30
                color: "transparent"

                onClicked: {
                    Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "sidebarLeft", "toggle"]);
                    Quickshell.execDetached(["bash", "-c", Config.options.apps.network]);
                }

                contentItem: Item {
                    anchors.centerIn: parent
                    implicitWidth: buttonText.implicitWidth
                    WText {
                        id: buttonText
                        anchors.centerIn: parent
                        text: qsTr("More Internet settings")
                        color: moreSettingsButton.pressed ? Looks.colors.fg : Looks.colors.fg1
                    }
                }
            }
        }
    }
}
