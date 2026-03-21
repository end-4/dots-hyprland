import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Popup {
    id: root

    property int countdown: 10
    property var revertCallback: null

    signal confirmed
    signal reverted

    x: parent ? Math.max(0, (parent.width - width) / 2) : 100
    y: parent ? Math.max(0, (parent.height - height) / 2) : 100
    width: 380
    height: contentColumn.implicitHeight + 40
    padding: 20
    modal: true
    dim: true
    closePolicy: Popup.NoAutoClose

    Overlay.modal: Rectangle {
        color: "#E6000000"
    }

    background: Rectangle {
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.large
        border.width: 1
        border.color: Appearance.colors.colOutline
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: root.opened
        onTriggered: {
            root.countdown--;
            if (root.countdown <= 0) {
                root.revert();
                root.close();
            }
        }
    }

    function revert() {
        if (typeof revertCallback === "function")
            revertCallback();
        reverted();
    }

    onOpened: countdown = 10

    ColumnLayout {
        id: contentColumn
        width: parent.width - 40
        spacing: 16

        StyledText {
            text: Translation.tr("Keep display settings?")
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.Medium
            color: Appearance.colors.colOnSecondaryContainer
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2

            StyledText {
                anchors.centerIn: parent
                text: Translation.tr("Reverting in %1 seconds...").arg(root.countdown)
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: Appearance.colors.colPrimary
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Item { Layout.fillWidth: true }
            RippleButton {
                Layout.preferredWidth: 100
                buttonRadius: Appearance.rounding.small
                onClicked: {
                    root.revert();
                    root.close();
                }
                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("Revert")
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
            RippleButton {
                Layout.preferredWidth: 120
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Appearance.colors.colPrimaryHover
                onClicked: {
                    countdownTimer.stop();
                    confirmed();
                    root.close();
                }
                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("Keep")
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
    }
}
