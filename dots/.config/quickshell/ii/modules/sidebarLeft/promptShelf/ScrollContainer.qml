import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io


Rectangle {
  id: root
  anchors.fill: parent
  color: "#282C34" // Dark background for visibility

  Item { // Messages
        Layout.fillWidth: true
        Layout.fillHeight: true
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: swipeView.width
                height: swipeView.height
                radius: Appearance.rounding.small
            }
        }

        ScrollEdgeFade {
            target: messageListView
            vertical: true
        }

        StyledListView { // Message list
            id: messageListView
            anchors.fill: parent
            spacing: 10
            popin: false

            touchpadScrollFactor: Config.options.interactions.scrolling.touchpadScrollFactor * 1.4
            mouseScrollFactor: Config.options.interactions.scrolling.mouseScrollFactor * 1.4

            // property int lastResponseLength: 0
            // onContentHeightChanged: {
            //     if (atYEnd) Qt.callLater(positionViewAtEnd);
            // }
            // onCountChanged: { // Auto-scroll when new messages are added
            //     if (atYEnd) Qt.callLater(positionViewAtEnd);
            // }

            add: null // Prevent function calls from being janky

            model: 1
            delegate: PromptContainer {
              id: xd
              
            }
        }
    }

    DescriptionBox {
        text: root.suggestionList[suggestions.selectedIndex]?.description ?? ""
        showArrows: root.suggestionList.length > 1
    }
}