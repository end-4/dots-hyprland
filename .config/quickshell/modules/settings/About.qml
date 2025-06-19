import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"

ContentPage {
    StyledText {
        text: qsTr("About page")
        font.pixelSize: Appearance.font.pixelSize.larger
    }
}