import qs  
import qs.services  
import qs.modules.common  
import qs.modules.common.widgets  
import qs.modules.common.functions  
import qs.modules.ii.sidebarLeft  
import QtQuick  
import QtQuick.Controls  
import QtQuick.Layouts  
import Quickshell  
import Qt5Compat.GraphicalEffects  
  
Rectangle {  
    id: root  
    property var responseData  
    property var tagInputField  
  
    property string previewDownloadPath  
    property string downloadPath  
  
    property real availableWidth: parent.width  
    property real rowTooShortThreshold: 190  
    property real imageSpacing: 5  
    property real responsePadding: 5  
  
    anchors.left: parent?.left  
    anchors.right: parent?.right  
    implicitHeight: columnLayout.implicitHeight + root.responsePadding * 2  
  
    Component.onCompleted: {  
        availableWidth = parent.width  
    }  
  
    Connections {  
        target: parent  
        function onWidthChanged() {  
            updateWidthTimer.restart()  
        }  
    }  
  
    Timer {  
        id: updateWidthTimer  
        interval: 100  
        onTriggered: {  
            availableWidth = parent.width  
        }  
    }  
  
    radius: Appearance.rounding.normal  
    color: Appearance.colors.colLayer1  
  
    ColumnLayout {  
        id: columnLayout  
          
        anchors.left: parent.left  
        anchors.right: parent.right  
        anchors.top: parent.top  
        anchors.margins: responsePadding  
        spacing: root.imageSpacing  
  
        RowLayout {  
            Rectangle {  
                id: providerNameWrapper  
                color: Appearance.colors.colSecondaryContainer  
                radius: Appearance.rounding.small  
                implicitWidth: providerName.implicitWidth + 10 * 2  
                implicitHeight: Math.max(providerName.implicitHeight + 5 * 2, 30)  
                Layout.alignment: Qt.AlignVCenter  
  
                StyledText {  
                    id: providerName  
                    anchors.centerIn: parent  
                    font.pixelSize: Appearance.font.pixelSize.large  
                    color: Appearance.m3colors.m3onSecondaryContainer  
                    text: UnsplashWallpapers.providers[root.responseData.provider].name  
                }  
            }  
            Item { Layout.fillWidth: true }  
            Item {  
                visible: root.responseData.page != "" && root.responseData.page > 0  
                implicitWidth: Math.max(pageNumber.implicitWidth + 10 * 2, 30)  
                implicitHeight: pageNumber.implicitHeight + 5 * 2  
                Layout.alignment: Qt.AlignVCenter  
  
                StyledText {  
                    id: pageNumber  
                    anchors.centerIn: parent  
                    font.pixelSize: Appearance.font.pixelSize.smaller  
                    color: Appearance.colors.colOnLayer2  
                    text: Translation.tr("Page %1").arg(root.responseData.page)  
                }  
            }  
        }  
  
        StyledFlickable {  
            id: tagsFlickable  
            visible: root.responseData.tags.length > 0  
            Layout.alignment: Qt.AlignLeft  
            Layout.fillWidth: true  
            implicitHeight: tagRowLayout.implicitHeight  
            contentWidth: tagRowLayout.implicitWidth  
  
            clip: true  
            layer.enabled: true  
            layer.effect: OpacityMask {  
                maskSource: Rectangle {  
                    width: tagsFlickable.width  
                    height: tagsFlickable.height  
                    gradient: Gradient {  
                        orientation: Gradient.Horizontal  
                        GradientStop { position: 0.0; color: "white" }  
                        GradientStop { position: 0.9; color: "white" }  
                        GradientStop { position: 1.0; color: "transparent" }  
                    }  
                }  
            }  
  
            RowLayout {  
                id: tagRowLayout  
                spacing: 5  
  
                Repeater {  
                    model: root.responseData.tags  
                    delegate: Rectangle {  
                        required property string modelData  
                        color: Appearance.colors.colLayer2  
                        radius: Appearance.rounding.small  
                        implicitWidth: tagText.implicitWidth + 10 * 2  
                        implicitHeight: Math.max(tagText.implicitHeight + 5 * 2, 25)  
  
                        StyledText {  
                            id: tagText  
                            anchors.centerIn: parent  
                            font.pixelSize: Appearance.font.pixelSize.smaller  
                            color: Appearance.colors.colOnLayer2  
                            text: modelData  
                        }  
                    }  
                }  
            }  
        }  
  
        StyledText {  
            visible: root.responseData.message.length > 0  
            Layout.fillWidth: true  
            text: root.responseData.message  
            wrapMode: Text.Wrap  
            color: Appearance.colors.colOnLayer2  
            textFormat: Text.MarkdownText  
            onLinkActivated: (link) => {  
                Qt.openUrlExternally(link)  
                GlobalStates.sidebarLeftOpen = false  
            }  
            PointingHandLinkHover {}  
        }  
  
        Repeater {  
            model: ScriptModel {  
                values: {  
                    let i = 0;  
                    let rows = [];  
                    const responseList = root.responseData.images;  
                    const minRowHeight = rowTooShortThreshold;  
                    const availableImageWidth = availableWidth - root.imageSpacing - (responsePadding * 2);  
  
                    while (i < responseList.length) {  
                        let row = {  
                            height: 0,  
                            images: [],  
                        };  
                        let j = i;  
                        let combinedAspect = 0;  
                        let rowHeight = 0;  
  
                        while (j < responseList.length) {  
                            combinedAspect += responseList[j].aspect_ratio;  
                            let imagesInRow = j - i + 1;  
                            let totalSpacing = root.imageSpacing * (imagesInRow - 1);  
                            let rowAvailableWidth = availableImageWidth - totalSpacing;  
                            rowHeight = rowAvailableWidth / combinedAspect;  
                            if (rowHeight < minRowHeight) {  
                                combinedAspect -= responseList[j].aspect_ratio;  
                                imagesInRow -= 1;  
                                totalSpacing = root.imageSpacing * (imagesInRow - 1);  
                                rowAvailableWidth = availableImageWidth - totalSpacing;  
                                rowHeight = rowAvailableWidth / combinedAspect;  
                                break;  
                            }  
                            j++;  
                        }  
  
                        if (j === i) {  
                            row.images.push(responseList[i]);  
                            row.height = availableImageWidth / responseList[i].aspect_ratio;  
                            rows.push(row);  
                            i++;  
                        } else {  
                            for (let k = i; k < j; k++) {  
                                row.images.push(responseList[k]);  
                            }  
                            let imagesInRow = j - i;  
                            let totalSpacing = root.imageSpacing * (imagesInRow - 1);  
                            let rowAvailableWidth = availableImageWidth - totalSpacing;  
                            row.height = rowAvailableWidth / combinedAspect;  
                            rows.push(row);  
                            i = j;  
                        }  
                    }  
                    return rows;  
                }  
            }  
            delegate: RowLayout {  
                id: imageRow  
                required property var modelData  
                property var rowHeight: modelData.height  
                spacing: root.imageSpacing  
  
                Repeater {  
                    model: modelData.images  
                    delegate: UnsplashImage {  
                        required property var modelData  
                        imageData: modelData  
                        rowHeight: imageRow.rowHeight  
                        imageRadius: imageRow.modelData.images.length == 1 ? 50 : Appearance.rounding.normal  
                        manualDownload: true  
                        previewDownloadPath: root.previewDownloadPath  
                        downloadPath: root.downloadPath  
                    }  
                }  
            }  
        }  
  
        RippleButton {  
            id: button  
            visible: root.responseData.page != "" && root.responseData.page > 0  
  
            Layout.alignment: Qt.AlignRight  
            implicitHeight: 30  
            leftPadding: 10  
            rightPadding: 5  
  
            onClicked: {  
                tagInputField.text = `${responseData.tags.join(" ")} ${parseInt(root.responseData.page) + 1}`  
                tagInputField.accept()  
            }  
  
            buttonRadius: Appearance.rounding.small  
            colBackground: Appearance.colors.colSurfaceContainerHighest  
            colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover  
            colRipple: Appearance.colors.colSurfaceContainerHighestActive              
  
            contentItem: Item {  
                anchors.fill: parent  
                implicitHeight: nextPageRow.implicitHeight  
                implicitWidth: nextPageRow.implicitWidth  
  
                RowLayout {  
                    id: nextPageRow  
                    anchors.centerIn: parent  
                    spacing: 0  
                    StyledText {  
                        Layout.alignment: Qt.AlignVCenter  
                        verticalAlignment: Text.AlignVCenter  
                        text: "Next page"  
                        color: Appearance.m3colors.m3onSurface  
                    }  
                    MaterialSymbol {  
                        Layout.alignment: Qt.AlignVCenter  
                        iconSize: Appearance.font.pixelSize.larger  
                        color: Appearance.m3colors.m3onSurface  
                        text: "chevron_right"  
                    }  
                }  
            }  
        }  
    }  
}