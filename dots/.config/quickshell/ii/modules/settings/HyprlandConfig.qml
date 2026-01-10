import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

        ContentSection {
            icon: "window"
            title: Translation.tr("General Settings")

            ConfigRow {
                ConfigSpinBox {
                    icon: "grid_view"
                    text: Translation.tr("Inner Gaps")
                    value: Config.options.hyprland.general.gaps.gapsIn
                    from: 0
                    to: 50
                    stepSize: 1
                    onValueChanged: {
                        Config.options.hyprland.general.gaps.gapsIn = value;
                    }
                }
                ConfigSpinBox {
                    icon: "expand_content"
                    text: Translation.tr("Outer Gaps")
                    value: Config.options.hyprland.general.gaps.gapsOut
                    from: 0
                    to: 50
                    stepSize: 1
                    onValueChanged: {
                        Config.options.hyprland.general.gaps.gapsOut = value;
                    }
                }
            }

            ConfigRow {
                ConfigSpinBox {
                    icon: "◻"
                    text: Translation.tr("Workspace Gaps")
                    value: Config.options.hyprland.general.gaps.gapsWorkspaces
                    from: 0
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.hyprland.general.gaps.gapsWorkspaces = value;
                    }
                }
                ConfigSpinBox {
                    icon: "border_outer"
                    text: Translation.tr("Border Size")
                    value: Config.options.hyprland.general.border.borderSize
                    from: 0
                    to: 10
                    stepSize: 1
                    onValueChanged: {
                        Config.options.hyprland.general.border.borderSize = value;
                    }
                }
            }
        }

        ContentSection {
            icon: "texture"
            title: Translation.tr("Decoration")

            ContentSubsection{
                title: Translation.tr("Rounding")
                ConfigSpinBox {
                    icon: "rounded_corner"
                    text: Translation.tr("Corner Rounding")
                    value: Config.options.hyprland.decoration.rounding
                    from: 0
                    to: 20
                    stepSize: 1
                    onValueChanged: {
                        Config.options.hyprland.decoration.rounding = value;
                    }
                }
            }
            ContentSubsection{
                title: Translation.tr("Window blur rules")
                ConfigSwitch {
                    buttonIcon: "blur_on"
                    text: Translation.tr("Enable Blur")
                    checked: Config.options.hyprland.decoration.blur.enabled
                    onCheckedChanged: {
                        Config.options.hyprland.decoration.blur.enabled = checked;
                    }
                }

                ConfigRow {
                    enabled: Config.options.hyprland.decoration.blur.enabled
                    ConfigSpinBox {
                        icon: "blur_medium"
                        text: Translation.tr("Blur Size")
                        value: Config.options.hyprland.decoration.blur.size
                        from: 1
                        to: 20
                        stepSize: 1
                        onValueChanged: {
                            Config.options.hyprland.decoration.blur.size = value;
                        }
                    }
                    ConfigSpinBox {
                        icon: "layers"
                        text: Translation.tr("Blur Passes")
                        value: Config.options.hyprland.decoration.blur.passes
                        from: 0
                        to: 10
                        stepSize: 1
                        onValueChanged: {
                            Config.options.hyprland.decoration.blur.passes = value;
                        }
                    }
                }
            }
        }

        ContentSection {
            icon: "opacity"
            title: Translation.tr("Window Opacity Rules")

            ConfigRow {
                ConfigSpinBox {
                    icon: "visibility"
                    text: Translation.tr("Active Opacity (%)")
                    value: Config.options.hyprland.windowRules.opacityActive * 100
                    from: 10
                    to: 100
                    stepSize: 1
                    onValueChanged: {
                        Config.options.hyprland.windowRules.opacityActive = value / 100;
                        Config.options.hyprland.terminal.kittyBackgroundOpacity = value / 100;
                    }
                }
                ConfigSpinBox {
                    icon: "visibility_off"
                    text: Translation.tr("Inactive Opacity (%)")
                    value: Config.options.hyprland.windowRules.opacityInactive * 100
                    from: 10
                    to: 100
                    stepSize: 1
                    onValueChanged: {
                        Config.options.hyprland.windowRules.opacityInactive = value / 100;
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Example Usage")

                StyledText {
                    text: Translation.tr("Set global opacity values that can be used in your window rules.\nUse $OPACITY_ACTIVE and $OPACITY_INACTIVE variables in custom/rules.conf\nwindowrulev2 = opacity $OPACITY_ACTIVE override $OPACITY_INACTIVE override, class:^(kate)$")
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    Layout.leftMargin: 48
                    Layout.rightMargin: 48
                }
            }

            RippleButton {
                Layout.topMargin: 15
                buttonRadius: Appearance.rounding.normal
                topPadding: 14
                bottomPadding: 14
                leftPadding: 40
                rightPadding: 40
                colBackground: Appearance.colors.colPrimaryContainer
                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                Layout.alignment: Qt.AlignCenter

                onClicked: {
                    Quickshell.execDetached([Directories.scriptPath + "/hyprland/apply-hyprland-config.sh"]);
                }
                contentItem: RowLayout {
                    StyledText {
                        text: Translation.tr("Apply")
                        color: Appearance.colors.colOnPrimaryContainer
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }
                }
            }

            StyledText {
                text: Translation.tr("Note: Settings will be automatically applied when you toggle light/dark mode\nSome apps need to be reloaded for this to apply")
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.smaller
                Layout.topMargin: 10
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
}
