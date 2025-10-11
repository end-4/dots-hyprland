import qs
import qs.modules.common.widgets
import qs.modules.common
import qs.services
import Quickshell
import "../"

MaterialQuickToggleButton {
    id: root
    buttonSize: 2
    toggled: GlobalStates.oskOpen
    buttonIcon: "keyboard"
    titleText: "Keyboard"
    altText: "Click me"
    onClicked: {
        GlobalStates.sidebarRightOpen = false;
        onClicked: GlobalStates.oskOpen = !GlobalStates.oskOpen
    }
    StyledToolTip {
        text: "Toggle Keyboard"
    }
}