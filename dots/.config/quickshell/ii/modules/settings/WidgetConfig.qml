import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "clock_loader_60"
        title: Translation.tr("Clock")

        ConfigSwitch {
            buttonIcon: "nest_clock_farsight_analog"
            text: Translation.tr("Show clock")
            checked: Config.options.background.clock.show
            onCheckedChanged: {
                Config.options.background.clock.show = checked;
            }
        }
            

        ConfigSpinBox {
            icon: "loupe"
            text: Translation.tr("Scale (%)")
            value: Config.options.background.clock.scale * 100
            from: 1
            to: 200
            stepSize: 2
            onValueChanged: {
                Config.options.background.clock.scale = value / 100;
            }
        }

        ContentSubsection {
            title: Translation.tr("Clock style")
            ConfigSelectionArray {
                currentValue: Config.options.background.clock.style
                onSelected: newValue => {
                    Config.options.background.clock.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Simple digital"),
                        icon: "timer_10",
                        value: "digital"
                    },
                    {
                        displayName: Translation.tr("Material cookie"),
                        icon: "cookie",
                        value: "cookie"
                    }
                ]
            }
        }

        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Cookie clock settings")

            ConfigSwitch {
                buttonIcon: "wand_stars"
                text: Translation.tr("Auto styling with Gemini")
                checked: Config.options.background.clock.cookie.aiStyling
                onCheckedChanged: {
                    Config.options.background.clock.cookie.aiStyling = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Uses Gemini to categorize the wallpaper then picks a preset based on it.\nYou'll need to set Gemini API key on the left sidebar first.\nImages are downscaled for performance, but just to be safe,\ndo not select wallpapers with sensitive information.")
                }
            }

            ConfigSpinBox {
                icon: "add_triangle"
                text: Translation.tr("Sides")
                value: Config.options.background.clock.cookie.sides
                from: 0
                to: 40
                stepSize: 1
                onValueChanged: {
                    Config.options.background.clock.cookie.sides = value;
                }
            }

            ConfigSwitch {
                buttonIcon: "autoplay"
                text: Translation.tr("Constantly rotate")
                checked: Config.options.background.clock.cookie.constantlyRotate
                onCheckedChanged: {
                    Config.options.background.clock.cookie.constantlyRotate = checked;
                }
                StyledToolTip {
                    text: "Makes the clock always rotate. This is extremely expensive\n(expect 50% usage on Intel UHD Graphics) and thus impractical."
                }
            }

            ConfigRow {

                ConfigSwitch {
                    enabled: Config.options.background.clock.style === "cookie" && Config.options.background.clock.cookie.dialNumberStyle === "dots" || Config.options.background.clock.cookie.dialNumberStyle === "full"
                    buttonIcon: "brightness_7"
                    text: Translation.tr("Hour marks")
                    checked: Config.options.background.clock.cookie.hourMarks
                    onEnabledChanged: {
                        checked = Config.options.background.clock.cookie.hourMarks;
                    }
                    onCheckedChanged: {
                        Config.options.background.clock.cookie.hourMarks = checked;
                    }
                    StyledToolTip {
                        text: "Can only be turned on using the 'Dots' or 'Full' dial style for aesthetic reasons"
                    }
                }

                ConfigSwitch {
                    enabled: Config.options.background.clock.style === "cookie" && Config.options.background.clock.cookie.dialNumberStyle !== "numbers"
                    buttonIcon: "timer_10"
                    text: Translation.tr("Digits in the middle")
                    checked: Config.options.background.clock.cookie.timeIndicators
                    onEnabledChanged: {
                        checked = Config.options.background.clock.cookie.timeIndicators;
                    }
                    onCheckedChanged: {
                        Config.options.background.clock.cookie.timeIndicators = checked;
                    }
                    StyledToolTip {
                        text: "Can't be turned on when using 'Numbers' dial style for aesthetic reasons"
                    }
                }
            }
        }
        
        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Dial style")
            ConfigSelectionArray {
                currentValue: Config.options.background.clock.cookie.dialNumberStyle
                onSelected: newValue => {
                    Config.options.background.clock.cookie.dialNumberStyle = newValue;
                    if (newValue !== "dots" && newValue !== "full") {
                        Config.options.background.clock.cookie.hourMarks = false;
                    }
                    if (newValue === "numbers") {
                        Config.options.background.clock.cookie.timeIndicators = false;
                    }
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "none"
                    },
                    {
                        displayName: Translation.tr("Dots"),
                        icon: "graph_6",
                        value: "dots"
                    },
                    {
                        displayName: Translation.tr("Full"),
                        icon: "history_toggle_off",
                        value: "full"
                    },
                    {
                        displayName: Translation.tr("Numbers"),
                        icon: "counter_1",
                        value: "numbers"
                    }
                ]
            }
        }

        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Hour hand")
            ConfigSelectionArray {
                currentValue: Config.options.background.clock.cookie.hourHandStyle
                onSelected: newValue => {
                    Config.options.background.clock.cookie.hourHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Hollow"),
                        icon: "circle",
                        value: "hollow"
                    },
                    {
                        displayName: Translation.tr("Fill"),
                        icon: "eraser_size_5",
                        value: "fill"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Minute hand")

            ConfigSelectionArray {
                currentValue: Config.options.background.clock.cookie.minuteHandStyle
                onSelected: newValue => {
                    Config.options.background.clock.cookie.minuteHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Thin"),
                        icon: "line_end",
                        value: "thin"
                    },
                    {
                        displayName: Translation.tr("Medium"),
                        icon: "eraser_size_2",
                        value: "medium"
                    },
                    {
                        displayName: Translation.tr("Bold"),
                        icon: "eraser_size_4",
                        value: "bold"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Second hand")

            ConfigSelectionArray {
                currentValue: Config.options.background.clock.cookie.secondHandStyle
                onSelected: newValue => {
                    Config.options.background.clock.cookie.secondHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Line"),
                        icon: "line_end",
                        value: "line"
                    },
                    {
                        displayName: Translation.tr("Dot"),
                        icon: "adjust",
                        value: "dot"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Date style")

            ConfigSelectionArray {
                currentValue: Config.options.background.clock.cookie.dateStyle
                onSelected: newValue => {
                    Config.options.background.clock.cookie.dateStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Bubble"),
                        icon: "bubble_chart",
                        value: "bubble"
                    },
                    {
                        displayName: Translation.tr("Border"),
                        icon: "rotate_right",
                        value: "border"
                    },
                    {
                        displayName: Translation.tr("Rect"),
                        icon: "rectangle",
                        value: "rect"
                    }
                ]
            }
        }
    }
}