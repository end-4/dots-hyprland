import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"

ContentPage {
    StyledText {
        text: qsTr("General page")
        font.pixelSize: Appearance.font.pixelSize.larger
    }
}