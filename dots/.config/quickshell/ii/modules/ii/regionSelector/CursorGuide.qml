import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    property var action
    property var selectionMode

    property string description: {
        const isFullscreen = root.selectionMode === RegionSelection.SelectionMode.Fullscreen;
        switch (root.action) {
        case RegionSelection.SnipAction.Copy:
        case RegionSelection.SnipAction.Edit:
            return isFullscreen ? Translation.tr("Fullscreen capture") : Translation.tr("Copy region (LMB) or annotate (RMB)");
        case RegionSelection.SnipAction.Search:
            return isFullscreen ? Translation.tr("Search fullscreen with Lens") : Translation.tr("Search with Google Lens");
        case RegionSelection.SnipAction.CharRecognition:
            return isFullscreen ? Translation.tr("Recognize fullscreen text") : Translation.tr("Recognize text");
        case RegionSelection.SnipAction.Record:
        case RegionSelection.SnipAction.RecordWithSound:
            return isFullscreen ? Translation.tr("Record fullscreen") : Translation.tr("Record region");
        default:
            return "";
        }
    }
    property string materialSymbol: {
        const isFullscreen = root.selectionMode === RegionSelection.SelectionMode.Fullscreen;
        if (isFullscreen) {
            return "fullscreen";
        }
        switch (root.action) {
        case RegionSelection.SnipAction.Copy:
        case RegionSelection.SnipAction.Edit:
            return "content_cut";
        case RegionSelection.SnipAction.Search:
            return "image_search";
        case RegionSelection.SnipAction.CharRecognition:
            return "document_scanner";
        case RegionSelection.SnipAction.Record:
        case RegionSelection.SnipAction.RecordWithSound:
            return "videocam";
        default:
            return "";
        }
    }

    property bool showDescription: true
    function hideDescription() {
        root.showDescription = false
    }
    Timer {
        id: descTimeout
        interval: 1000
        running: true
        onTriggered: {
            root.hideDescription()
        }
    }
    onActionChanged: {
        root.showDescription = true
        descTimeout.restart()
    }

    property int margins: 8
    implicitWidth: content.implicitWidth + margins * 2
    implicitHeight: content.implicitHeight + margins * 2

    Rectangle {
        id: content
        anchors.centerIn: parent

        property real padding: 8
        implicitHeight: 38
        implicitWidth: root.showDescription ? contentRow.implicitWidth + padding * 2 : implicitHeight
        clip: true

        topLeftRadius: 6
        bottomLeftRadius: implicitHeight - topLeftRadius
        bottomRightRadius: bottomLeftRadius
        topRightRadius: bottomLeftRadius

        color: Appearance.colors.colPrimary

        Behavior on topLeftRadius {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on implicitWidth {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        Row {
            id: contentRow
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: content.padding
            }
            spacing: 12

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 22
                color: Appearance.colors.colOnPrimary
                animateChange: true
                text: root.materialSymbol
            }

            FadeLoader {
                id: descriptionLoader
                anchors.verticalCenter: parent.verticalCenter
                shown: root.showDescription
                sourceComponent: StyledText {
                    color: Appearance.colors.colOnPrimary
                    text: root.description
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                }
            }
        }
    }
}
