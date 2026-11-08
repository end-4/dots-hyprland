import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.quickToggles

QuickToggleButton {
    id: root
    buttonIcon: "gamepad"
    enabled: gameMode.available
    toggled: gameMode.toggled
    onClicked: gameMode.mainAction()

    // Share the model with the Android and Waffle panels. Its option reader
    // supports both boolean Lua values and legacy numeric values.
    GameModeToggle { id: gameMode }
    StyledToolTip { text: gameMode.tooltipText }
}
