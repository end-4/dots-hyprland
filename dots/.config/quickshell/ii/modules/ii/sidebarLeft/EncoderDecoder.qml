import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarLeft.encoderDecoder
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * Encoder/Decoder widget with URL and Base64 encoding/decoding.
 */
Item {
    id: root

    // Sizes
    property real padding: 4

    // Tab management
    property var tabButtonList: [
        {"icon": "link", "name": Translation.tr("URL")},
        {"icon": "code", "name": Translation.tr("Base64")}
    ]

    onFocusChanged: (focus) => {
        if (focus && swipeView.currentItem) {
            swipeView.currentItem.forceActiveFocus()
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: 10

        Toolbar {
            Layout.alignment: Qt.AlignHCenter
            enableShadow: false
            ToolbarTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                tabButtonList: root.tabButtonList
                currentIndex: swipeView.currentIndex
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: swipeView.implicitWidth
            implicitHeight: swipeView.implicitHeight
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            SwipeView {
                id: swipeView
                anchors.fill: parent
                currentIndex: tabBar.currentIndex
                clip: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: swipeView.width
                        height: swipeView.height
                        radius: Appearance.rounding.small
                    }
                }

                UrlEncoder {
                    id: urlEncoder
                }

                Base64Encoder {
                    id: base64Encoder
                }
            }
        }
    }
}
