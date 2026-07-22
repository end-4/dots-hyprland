pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

// Box, Layout version
// A type that's both capable of being rows and columns
// Qt Row is just a locked down Grid smh
// Calling it a Box because that's how row-or-column widget is called in Gtk
GridLayout {
    id: root

    property bool vertical: false
    columns: vertical ? 1 : -1
    rows: vertical ? -1 : 1

    property alias spacing: root.rowSpacing
    columnSpacing: rowSpacing
}
