import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    property var responseData
    property var tagInputField

    property string previewDownloadPath
    property string downloadPath
    property string nsfwPath

    onResponseDataChanged: {
        console.log("Response data changed:", responseData)
    }

    property real availableWidth: parent.width ?? 0
    property real rowTooShortThreshold: 100
    property real imageSpacing: 5
    property real responsePadding: 5

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: columnLayout.implicitHeight + root.responsePadding * 2

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    ColumnLayout {
        id: columnLayout
        
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: responsePadding
        spacing: root.imageSpacing

        RowLayout { // Header
            Rectangle { // Provider name
                id: providerNameWrapper
                color: Appearance.m3colors.m3secondaryContainer
                radius: Appearance.rounding.small
                implicitWidth: providerName.implicitWidth + 10 * 2
                implicitHeight: Math.max(providerName.implicitHeight + 5 * 2, 30)
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: providerName
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.m3colors.m3onSecondaryContainer
                    text: Booru.providers[root.responseData.provider].name
                }
            }
            Item { Layout.fillWidth: true }
            Item { // Page number
                visible: root.responseData.page != "" && root.responseData.page > 0
                implicitWidth: Math.max(pageNumber.implicitWidth + 10 * 2, 30)
                implicitHeight: pageNumber.implicitHeight + 5 * 2
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: pageNumber
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer2
                    text: `Page ${root.responseData.page}`
                }
            }
        }

        Flickable { // Tag strip
            id: tagsFlickable
            visible: root.responseData.tags.length > 0
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: {
                console.log(root.responseData)
                return true
            }
            implicitHeight: tagRowLayout.implicitHeight
            // height: tagRowLayout.implicitHeight
            contentWidth: tagRowLayout.implicitWidth

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: tagsFlickable.width
                    height: tagsFlickable.height
                    radius: Appearance.rounding.small
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: Appearance.animation.elementDecel.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }
            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Appearance.animation.elementDecel.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }

            RowLayout {
                id: tagRowLayout
                Layout.alignment: Qt.AlignBottom

                Repeater {
                    id: tagRepeater
                    model: root.responseData.tags

                    BooruTagButton {
                        Layout.fillWidth: false
                        buttonText: modelData
                        onClicked: {
                            if(root.tagInputField.text.length !== 0) root.tagInputField.text += " "
                            root.tagInputField.text += modelData
                        }
                    }
                }
                
            }
        }

        StyledText { // Message
            id: messageText
            Layout.fillWidth: true
            visible: root.responseData.message.length > 0
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: root.responseData.message
            wrapMode: Text.WordWrap
            Layout.margins: responsePadding
            textFormat: Text.MarkdownText
            onLinkActivated: (link) => {
                Qt.openUrlExternally(link)
                Hyprland.dispatch("global quickshell:sidebarLeftClose")
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton // Only for hover
                hoverEnabled: true
                cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }

        Repeater {
            model: {
                // Group two images every row, ensuring they are of the same height
                // If the height ends up being too small, put one image in the row and continue
                // In other words, this is similar to Android's gallery layout at largest zoom level
                let i = 0;
                let rows = [];
                const responseList = root.responseData.images;
                while (i < responseList.length) {
                    let row = {
                        height: 0,
                        images: [],
                    };
                    const availableImageWidth = availableWidth - root.imageSpacing - (responsePadding * 2)
                    if (i + 1 < responseList.length) {
                        const img1 = responseList[i];
                        const img2 = responseList[i + 1];
                        // Calculate combined height if both are in the same row
                        // Let h = row height, w1 = h * aspect1, w2 = h * aspect2
                        // w1 + w2 = availableWidth => h = availableWidth / (aspect1 + aspect2)
                        const combinedAspect = img1.aspect_ratio + img2.aspect_ratio;
                        const rowHeight = availableImageWidth / combinedAspect;
                        if (rowHeight >= rowTooShortThreshold) {
                            row.height = rowHeight;
                            row.images.push(img1);
                            row.images.push(img2);
                            rows.push(row);
                            i += 2;
                            continue;
                        }
                    }
                    // Otherwise, put only one image in the row
                    const rowHeight = availableImageWidth / responseList[i].aspect_ratio;
                    rows.push({
                        height: availableWidth / responseList[i].aspect_ratio,
                        images: [responseList[i]],
                    });
                    i += 1;
                }
                return rows;
            }
            delegate: RowLayout {
                id: imageRow
                property var rowHeight: modelData.height
                spacing: root.imageSpacing

                Repeater {
                    model: modelData.images
                    delegate: BooruImage {
                        imageData: modelData
                        rowHeight: imageRow.rowHeight
                        manualDownload: root.responseData.provider == "danbooru"
                        previewDownloadPath: root.previewDownloadPath
                        downloadPath: root.downloadPath
                        nsfwPath: root.nsfwPath
                    }
                }
            }
        }
    }
}