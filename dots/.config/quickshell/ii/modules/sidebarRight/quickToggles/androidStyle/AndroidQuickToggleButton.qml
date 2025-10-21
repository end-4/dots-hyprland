import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

GroupButton {
    id: root
    
    required property int buttonIndex
    required property var buttonData
    required property bool expandedSize
    required property string buttonIcon
    required property string name
    property string statusText: toggled ? Translation.tr("Active") : Translation.tr("Inactive")

    required property real baseCellWidth
    required property real baseCellHeight
    required property real cellSpacing
    required property int cellSize
    baseWidth: root.baseCellWidth * cellSize + cellSpacing * (cellSize - 1)
    baseHeight: root.baseCellHeight

    property bool editMode: false
    enableImplicitWidthAnimation: !editMode
    enableImplicitHeightAnimation: !editMode
    Behavior on baseWidth {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on baseHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    opacity: 0
    Component.onCompleted: {
        opacity = 1
    }
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    signal openMenu()

    padding: 6
    horizontalPadding: padding
    verticalPadding: padding

    colBackground: Appearance.colors.colLayer2
    colBackgroundToggled: (altAction && expandedSize) ? Appearance.colors.colLayer2 : Appearance.colors.colPrimary
    colBackgroundToggledHover: (altAction && expandedSize) ? Appearance.colors.colLayer2Hover : Appearance.colors.colPrimaryHover
    colBackgroundToggledActive: (altAction && expandedSize) ? Appearance.colors.colLayer2Active : Appearance.colors.colPrimaryActive
    buttonRadius: toggled ? Appearance.rounding.large : height / 2
    buttonRadiusPressed: Appearance.rounding.normal
    property color colText: (toggled && !(altAction && expandedSize)) ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
    property color colIcon: expandedSize ? (root.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer3) : colText

    contentItem: RowLayout {
        id: contentItem
        spacing: 4
        anchors {
            centerIn: root.expandedSize ? undefined : parent
            fill: root.expandedSize ? parent : undefined
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            Layout.topMargin: root.verticalPadding
            Layout.bottomMargin: root.verticalPadding
            implicitWidth: height
            radius: root.radius - root.verticalPadding
            color: {
                const baseColor = root.toggled ? Appearance.colors.colPrimary : Appearance.colors.colLayer3
                const transparentizeAmount = (root.altAction && root.expandedSize) ? 0 : 1
                return ColorUtils.transparentize(baseColor, transparentizeAmount)
            }

            MaterialSymbol {
                anchors.centerIn: parent
                fill: root.toggled ? 1 : 0
                iconSize: root.expandedSize ? 22 : 24
                color: root.colIcon
                text: root.buttonIcon
            }
        }

        Loader {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            visible: root.expandedSize
            active: visible
            sourceComponent: Column {
                StyledText {
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.name
                }

                StyledText {
                    visible: root.statusText
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    font {
                        pixelSize: Appearance.font.pixelSize.smaller
                        weight: Font.Light
                    }
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.statusText
                }
            }
        }
    }

    MouseArea { // Blocking MouseArea for edit interactions
        id: editModeInteraction
        visible: root.editMode
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        function toggleEnabled() {
            const index = root.buttonIndex;
            const toggleList = Config.options.sidebar.quickToggles.android.toggles;
            const buttonType = root.buttonData.type;
            if (!toggleList.find(toggle => toggle.type === buttonType)) {
                toggleList.push({ type: buttonType, size: 1 });
            } else {
                toggleList.splice(index, 1);
            }
        }

        function toggleSize() {
            const index = root.buttonIndex;
            const toggleList = Config.options.sidebar.quickToggles.android.toggles;
            const buttonType = root.buttonData.type;
            if (!toggleList.find(toggle => toggle.type === buttonType)) return;
            toggleList[index].size = 3 - toggleList[index].size; // Alternate between 1 and 2
        }

        function movePositionBy(offset) {
            const index = root.buttonIndex;
            const toggleList = Config.options.sidebar.quickToggles.android.toggles;
            const buttonType = root.buttonData.type;
            const targetIndex = index + offset;
            if (targetIndex < 0 || targetIndex >= toggleList.length) return;
            const temp = toggleList[index];
            toggleList[index] = toggleList[targetIndex];
            toggleList[targetIndex] = temp;
        }

        onReleased: (event) => {
            if (event.button === Qt.LeftButton)
                toggleEnabled();
        }
        onPressed: (event) => {
            if (event.button === Qt.RightButton) toggleSize();
        }
        onPressAndHold: (event) => { // Also toggle size
            toggleSize();
        }
        onWheel: (event) => {
            const index = root.buttonIndex;
            const toggleList = Config.options.sidebar.quickToggles.android.toggles;
            const buttonType = root.buttonData.type;
            if (event.angleDelta.y < 0) { // Move to right
                movePositionBy(1);
            } else if (event.angleDelta.y > 0) { // Move to left
                movePositionBy(-1);
            }
            event.accepted = true;
        }
    }
}
