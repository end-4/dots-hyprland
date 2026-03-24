import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower

Rectangle {
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)

    implicitWidth: contentItem.implicitWidth + root.horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + root.verticalPadding * 2
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    property real verticalPadding: 4
    property real horizontalPadding: 12

    Column {
        id: contentItem
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: Config.options.sidebar.quickSliders.showBrightness
            sourceComponent: QuickSlider {
                materialSymbol: "light_mode"
                secondaryMaterialSymbol: "wb_twilight"
                stopIndicatorValues: Hyprsunset.gamma !== 100 && root.brightnessMonitor?.brightness !== 0 ? [0.3 + root.brightnessMonitor?.brightness * 0.7] : []
                value: Hyprsunset.gamma === 100? 0.3 + root.brightnessMonitor?.brightness * 0.7 : Hyprsunset.gamma / 100 * 0.3
                tooltipContent: Hyprsunset.gamma === 100 ? `${Math.round(root.brightnessMonitor?.brightness * 100)}%` : `${Translation.tr("Gamma")} ${Hyprsunset.gamma}%`
                onMoved: {
                    if (value >= 0.3) {
                        // 0.3 - 1.0 brightness
                        root.brightnessMonitor.setBrightness((value - 0.3) / 0.7);
                        if (Hyprsunset.gamma !== 100) {
                            Hyprsunset.setGamma(100);
                        }
                    } else {
                        // 0 - 0.3 gamma
                        if (root.brightnessMonitor.brightness !== 0) {
                            root.brightnessMonitor.setBrightness(0);
                        }
                        Hyprsunset.setGamma(value * 100 / 0.3);
                    }
                }
            }
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: Config.options.sidebar.quickSliders.showVolume
            sourceComponent: QuickSlider {
                materialSymbol: "volume_up"
                value: Audio.sink.audio.volume
                onMoved: {
                    Audio.sink.audio.volume = value
                }
            }
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: Config.options.sidebar.quickSliders.showMic
            sourceComponent: QuickSlider {
                materialSymbol: "mic"
                value: Audio.source.audio.volume
                onMoved: {
                    Audio.source.audio.volume = value
                }
            }
        }
    }

    component QuickSlider: StyledSlider { 
        id: quickSlider
        required property string materialSymbol
        property string secondaryMaterialSymbol
        configuration: StyledSlider.Configuration.M
        stopIndicatorValues: []
        dividerValues: secondaryMaterialSymbol.length > 0 ? [secondaryIcon.iconLocation] : []
        
        MaterialSymbol {
            id: icon
            property bool nearFull: quickSlider.value >= 0.9
            anchors {
                verticalCenter: quickSlider.verticalCenter
                right: nearFull ? quickSlider.handle.right : quickSlider.right
                rightMargin: nearFull ? 14 : 8
            }
            iconSize: 20
            color: nearFull ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: quickSlider.materialSymbol

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on anchors.rightMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        MaterialSymbol {
            id: secondaryIcon
            visible: secondaryMaterialSymbol.length > 0
            property real iconLocation: 0.3
            property bool nearIcon: iconLocation - quickSlider.value <= 0.1 && iconLocation - quickSlider.value > (quickSlider.handleWidth + 8 - 14) / quickSlider.effectiveDraggingWidth
            anchors {
                verticalCenter: quickSlider.verticalCenter
                right: nearIcon ? quickSlider.handle.right : quickSlider.right
                rightMargin: nearIcon ? 14 : (1 - iconLocation) * quickSlider.effectiveDraggingWidth + quickSlider.rightPadding + 8
            }
            iconSize: 20
            color: quickSlider.value >= iconLocation - 0.1 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: secondaryMaterialSymbol

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}
