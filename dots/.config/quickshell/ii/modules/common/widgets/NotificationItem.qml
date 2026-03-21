import qs
import qs.modules.common
import qs.services
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

Item { // Notification item area
    id: root
    property var notificationObject
    property var notificationGroupParent: null
    property int cachedNotificationId: -1
    property string cachedAppIcon: ""
    property string cachedSummary: ""
    property string cachedImage: ""
    property var cachedUrgency: NotificationUrgency.Normal
    property bool dismissing: false
    property int dismissNotificationId: -1
    property QtObject frozenIcon: null
    property bool expanded: false
    property bool onlyNotification: false
    property real fontSize: Appearance.font.pixelSize.small
    property real padding: onlyNotification ? 0 : 8
    property real summaryElideRatio: 0.85

    property real dragConfirmThreshold: 70 // Drag further to discard notification
    property real dismissOvershoot: notificationIcon.implicitWidth + 20 // Account for gaps and bouncy animations
    property var qmlParent: root?.parent?.parent // There's something between this and the parent ListView
    property var parentDragIndex: qmlParent?.dragIndex ?? -1
    property var parentDragDistance: qmlParent?.dragDistance ?? 0
    property var dragIndexDiff: Math.abs(parentDragIndex - index)
    property real xOffset: dragIndexDiff == 0 ? parentDragDistance : 
        Math.abs(parentDragDistance) > dragConfirmThreshold ? 0 :
        dragIndexDiff == 1 ? (parentDragDistance * 0.3) :
        dragIndexDiff == 2 ? (parentDragDistance * 0.1) : 0

    implicitHeight: background.implicitHeight

    component FrozenIcon: QtObject {
        property string image: ""
        property string appIcon: ""
        property string summary: ""
        property int urgency: NotificationUrgency.Normal
    }
    Component {
        id: frozenIconComponent
        FrozenIcon {}
    }
    function syncCachedNotificationData() {
        if (root.dismissing)
            return;
        const notif = root.notificationObject;
        if (!notif)
            return;

        const notifId = notif.notificationId ?? -1;
        const isNewNotification = notifId !== root.cachedNotificationId;
        if (isNewNotification) {
            root.cachedNotificationId = notifId;
            root.cachedAppIcon = notif.appIcon ?? "";
            root.cachedSummary = notif.summary ?? "";
            root.cachedImage = notif.image ?? "";
        } else {
            if (notif.appIcon !== undefined && notif.appIcon !== "")
                root.cachedAppIcon = notif.appIcon;
            if (notif.summary !== undefined && notif.summary !== "")
                root.cachedSummary = notif.summary;
            if (notif.image !== undefined && notif.image !== "")
                root.cachedImage = notif.image;
        }

        root.cachedUrgency = notif.urgency === NotificationUrgency.Critical.toString() ?
            NotificationUrgency.Critical : NotificationUrgency.Normal;
    }
    function cacheDismissState() {
        const notif = root.notificationObject;
        root.dismissNotificationId = notif?.notificationId ?? root.cachedNotificationId;
        const img = (notif?.image !== undefined && notif?.image !== null && String(notif.image).length > 0) ?
            notif.image : root.cachedImage;
        const icon = (notif?.appIcon !== undefined && notif?.appIcon !== null && String(notif.appIcon).length > 0) ?
            notif.appIcon : root.cachedAppIcon;
        const sum = (notif?.summary !== undefined && notif?.summary !== null) ?
            (notif.summary ?? "") : root.cachedSummary;
        const urg = notif?.urgency === NotificationUrgency.Critical.toString() ?
            NotificationUrgency.Critical : root.cachedUrgency;
        root.frozenIcon = frozenIconComponent.createObject(root, {
            image: img || "",
            appIcon: icon || "",
            summary: sum || "",
            urgency: (urg === NotificationUrgency.Critical) ? NotificationUrgency.Critical : NotificationUrgency.Normal
        });
    }

    onNotificationObjectChanged: root.syncCachedNotificationData()
    Component.onCompleted: root.syncCachedNotificationData()

    Connections {
        target: root.notificationObject
        ignoreUnknownSignals: true
        enabled: !!root.notificationObject
        function onAppIconChanged() { root.syncCachedNotificationData(); }
        function onSummaryChanged() { root.syncCachedNotificationData(); }
        function onImageChanged() { root.syncCachedNotificationData(); }
        function onUrgencyChanged() { root.syncCachedNotificationData(); }
    }

    function destroyWithAnimation(left = false, fromDrag = false) {
        root.syncCachedNotificationData()
        root.cacheDismissState()
        root.dismissing = true
        if (root.onlyNotification && root.notificationGroupParent) {
            root.notificationGroupParent.cacheDismissIconState()
            root.notificationGroupParent.dismissing = true
        }
        const currentLeftMargin = background.anchors.leftMargin
        const dismissDirectionSign = fromDrag ?
            (currentLeftMargin >= 0 ? 1 : -1) :
            (left ? -1 : 1)
        background.anchors.leftMargin = currentLeftMargin; // Break binding at current drag position
        root.qmlParent.resetDrag()
        const targetLeftMargin = (root.width + root.dismissOvershoot) * dismissDirectionSign
        const remainingDistance = Math.abs(targetLeftMargin - currentLeftMargin)
        destroyAnimation.fromDrag = fromDrag
        destroyAnimation.slideDuration = fromDrag ?
            Math.max(80, Math.min(190, Math.round(remainingDistance / 3.2))) :
            Appearance.animation.elementMoveExit.duration
        destroyAnimation.left = dismissDirectionSign < 0;
        destroyAnimation.running = true;
    }

    TextMetrics {
        id: summaryTextMetrics
        font.pixelSize: root.fontSize
        text: root.notificationObject.summary || ""
    }

    SequentialAnimation { // Drag finish animation
        id: destroyAnimation
        property bool left: true
        property bool fromDrag: false
        property int slideDuration: Appearance.animation.elementMoveExit.duration
        running: false

        NumberAnimation {
            target: background.anchors
            property: "leftMargin"
            to: (root.width + root.dismissOvershoot) * (destroyAnimation.left ? -1 : 1)
            duration: destroyAnimation.slideDuration
            easing.type: destroyAnimation.fromDrag ? Easing.OutCubic : Appearance.animation.elementMoveExit.type
            easing.bezierCurve: destroyAnimation.fromDrag ? [] : Appearance.animation.elementMoveExit.bezierCurve
        }
        onFinished: () => {
            Notifications.discardNotification(root.dismissNotificationId);
        }
    }

    DragManager { // Drag manager
        id: dragManager
        anchors.fill: root
        anchors.leftMargin: root.expanded ? -notificationIcon.implicitWidth : 0
        interactive: expanded
        automaticallyReset: false
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                root.destroyWithAnimation();
            }
        }

        onDraggingChanged: () => {
            if (dragging) {
                root.qmlParent.dragIndex = root.index ?? root.parent.children.indexOf(root);
            }
        }

        onDragDiffXChanged: () => {
            root.qmlParent.dragDistance = dragDiffX;
        }

        onDragReleased: (diffX, diffY) => {
            if (Math.abs(diffX) > root.dragConfirmThreshold)
                root.destroyWithAnimation(diffX < 0, true);
            else 
                dragManager.resetDrag();
        }
    }

    NotificationAppIcon { // App icon
        id: notificationIcon
        readonly property string _img: root.dismissing && root.frozenIcon ? root.frozenIcon.image : root.cachedImage
        opacity: (!onlyNotification && _img !== "" && expanded) ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        image: _img
        appIcon: root.dismissing && root.frozenIcon ? root.frozenIcon.appIcon : root.cachedAppIcon
        summary: root.dismissing && root.frozenIcon ? root.frozenIcon.summary : root.cachedSummary
        urgency: root.dismissing && root.frozenIcon ? root.frozenIcon.urgency : root.cachedUrgency
        anchors.right: background.left
        anchors.top: background.top
        anchors.rightMargin: 10
    }

    Rectangle { // Background of notification item
        id: background
        width: parent.width
        anchors.left: parent.left
        radius: Appearance.rounding.small
        anchors.leftMargin: root.xOffset

        Behavior on anchors.leftMargin {
            enabled: !dragManager.dragging && !destroyAnimation.running
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
            }
        }

        color: (expanded && !onlyNotification) ? 
            (notificationObject.urgency == NotificationUrgency.Critical) ? 
                ColorUtils.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colLayer2, 0.35) :
                (Appearance.colors.colLayer3) :
            ColorUtils.transparentize(Appearance.colors.colLayer3)

        implicitHeight: expanded ? (contentColumn.implicitHeight + padding * 2) : summaryRow.implicitHeight
        Behavior on implicitHeight {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout { // Content column
            id: contentColumn
            anchors.fill: parent
            anchors.margins: expanded ? root.padding : 0
            spacing: 3

            Behavior on anchors.margins {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            RowLayout { // Summary row
                id: summaryRow
                visible: !root.onlyNotification || !root.expanded
                Layout.fillWidth: true
                implicitHeight: summaryText.implicitHeight
                StyledText {
                    id: summaryText
                    Layout.fillWidth: summaryTextMetrics.width >= summaryRow.implicitWidth * root.summaryElideRatio
                    visible: !root.onlyNotification
                    font.pixelSize: root.fontSize
                    color: Appearance.colors.colOnLayer3
                    elide: Text.ElideRight
                    text: root.notificationObject.summary || ""
                }
                StyledText {
                    opacity: !root.expanded ? 1 : 0
                    visible: opacity > 0
                    Layout.fillWidth: true
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    font.pixelSize: root.fontSize
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap // Needed for proper eliding????
                    maximumLineCount: 1
                    textFormat: Text.StyledText
                    text: {
                        return NotificationUtils.processNotificationBody(notificationObject.body, notificationObject.appName || notificationObject.summary).replace(/\n/g, "<br/>")
                    }
                }
            }

            ColumnLayout { // Expanded content
                id: expandedContentColumn
                Layout.fillWidth: true
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0

                StyledText { // Notification body (expanded)
                    id: notificationBodyText
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Layout.fillWidth: true
                    font.pixelSize: root.fontSize
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    textFormat: Text.RichText
                    text: {
                        return `<style>img{max-width:${expandedContentColumn.width}px;}</style>` + 
                            `${NotificationUtils.processNotificationBody(notificationObject.body, notificationObject.appName || notificationObject.summary).replace(/\n/g, "<br/>")}`
                    }

                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                        GlobalStates.sidebarRightOpen = false
                    }
                    
                    PointingHandLinkHover {}
                }

                Item {
                    Layout.fillWidth: true
                    implicitWidth: actionsFlickable.implicitWidth
                    implicitHeight: actionsFlickable.implicitHeight

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: actionsFlickable.width
                            height: actionsFlickable.height
                            radius: Appearance.rounding.small
                        }
                    }

                    ScrollEdgeFade {
                        target: actionsFlickable
                        vertical: false
                    }

                    StyledFlickable { // Notification actions
                        id: actionsFlickable
                        anchors.fill: parent
                        implicitHeight: actionRowLayout.implicitHeight
                        contentWidth: actionRowLayout.implicitWidth

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on height {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on implicitHeight {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        RowLayout {
                            id: actionRowLayout
                            Layout.alignment: Qt.AlignBottom

                            NotificationActionButton {
                                Layout.fillWidth: true
                                buttonText: Translation.tr("Close")
                                urgency: notificationObject.urgency
                                implicitWidth: (notificationObject.actions.length == 0) ? ((actionsFlickable.width - actionRowLayout.spacing) / 2) : 
                                    (contentItem.implicitWidth + leftPadding + rightPadding)

                                onClicked: {
                                    root.destroyWithAnimation()
                                }

                                contentItem: MaterialSymbol {
                                    iconSize: Appearance.font.pixelSize.larger
                                    horizontalAlignment: Text.AlignHCenter
                                    color: (notificationObject.urgency == NotificationUrgency.Critical) ? 
                                        Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                                    text: "close"
                                }
                            }

                            Repeater {
                                id: actionRepeater
                                model: notificationObject.actions
                                NotificationActionButton {
                                    id: notifAction
                                    required property var modelData
                                    Layout.fillWidth: true
                                    buttonText: modelData.text
                                    urgency: notificationObject.urgency
                                    onClicked: {
                                        Notifications.attemptInvokeAction(notificationObject.notificationId, modelData.identifier);
                                    }
                                }
                            }

                            NotificationActionButton {
                                Layout.fillWidth: true
                                urgency: notificationObject.urgency
                                implicitWidth: (notificationObject.actions.length == 0) ? ((actionsFlickable.width - actionRowLayout.spacing) / 2) : 
                                    (contentItem.implicitWidth + leftPadding + rightPadding)

                                onClicked: {
                                    Quickshell.clipboardText = notificationObject.body
                                    copyIcon.text = "inventory"
                                    copyIconTimer.restart()
                                }

                                Timer {
                                    id: copyIconTimer
                                    interval: 1500
                                    repeat: false
                                    onTriggered: {
                                        copyIcon.text = "content_copy"
                                    }
                                }

                                contentItem: MaterialSymbol {
                                    id: copyIcon
                                    iconSize: Appearance.font.pixelSize.larger
                                    horizontalAlignment: Text.AlignHCenter
                                    color: (notificationObject.urgency == NotificationUrgency.Critical) ? 
                                        Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                                    text: "content_copy"
                                }
                            }
                            
                        }
                    }
                }
            }
        }
    }
}
