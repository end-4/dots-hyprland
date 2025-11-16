import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

BarButton {
    id: root

    checked: GlobalStates.sidebarRightOpen
    onClicked: {
        GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen; // For now...
    }

    contentItem: Item {
        anchors.fill: parent
        implicitHeight: column.implicitHeight
        implicitWidth: column.implicitWidth
        Row {
            id: column
            anchors {
                top: parent.top
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            spacing: 4

            IconHoverArea {
                id: internetHoverArea
                iconItem: FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: WIcons.internetIcon
                }
            }

            IconHoverArea {
                id: volumeHoverArea
                iconItem: FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: {
                        const muted = Audio.sink?.audio.muted ?? false;
                        const volume = Audio.sink?.audio.volume ?? 0;
                        if (muted)
                            return volume > 0 ? "speaker-off" : "speaker-none";
                        if (volume == 0)
                            return "speaker-none";
                        if (volume < 0.5)
                            return "speaker-1";
                        return "speaker";
                    }
                }
            }

            IconHoverArea {
                id: batteryHoverArea
                iconItem: FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: WIcons.batteryIcon
                }
            }
        }
    }

    component IconHoverArea: MouseArea {
        id: hoverArea
        required property var iconItem
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        hoverEnabled: true
        implicitHeight: hoverArea.iconItem.implicitHeight
        implicitWidth: hoverArea.iconItem.implicitWidth

        onPressed: (event) => event.accepted = false; // Don't consume clicks

        children: [iconItem]
    }

    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip && internetHoverArea.containsMouse
        text: Translation.tr("%1\nInternet access").arg(Network.ethernet ? Translation.tr("Network") : Network.networkName)
    }
    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip && volumeHoverArea.containsMouse
        text: Translation.tr("Speakers (%1): %2") //
            .arg(Audio.sink?.nickname || Audio.sink?.description || Translation.tr("Unknown")) //
            .arg(Audio.sink?.audio.muted ? Translation.tr("Muted") : `${Math.round(Audio.sink?.audio.volume * 100) || 0}%`) //
    }
    BarToolTip {
        extraVisibleCondition: root.shouldShowTooltip && batteryHoverArea.containsMouse
        text: Translation.tr("Battery: %1%2") //
            .arg(`${Math.round(Battery.percentage * 100) || 0}%`) //
            .arg(Battery.isPluggedIn ? (" " + Translation.tr("(Plugged in)")) : "")
    }
}
