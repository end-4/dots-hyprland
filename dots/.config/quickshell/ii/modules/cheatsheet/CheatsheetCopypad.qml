import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root
    property real spacing: 8

    property var columns: []

    Process {
        id: reader
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split(/\r?\n/);
                var cols = [];
                var current = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (line.trim().length === 0) {
                        cols.push(current);
                        current = [];
                    } else {
                        current.push({ text: line });
                    }
                }
                cols.push(current);
                while (cols.length > 1 && cols[cols.length - 1].length === 0) {
                    cols.pop();
                }
                if (cols.length === 0) {
                    cols = [ [] ];
                }
                root.columns = cols;
            }
        }
    }

    Process {
        id: writer
        onExited: {
            Qt.callLater(function() { root.loadSnippets(); });
        }
    }

    Process {
        id: clipper
    }

    function loadSnippets() {
        var cmd = "cat \"$HOME/.config/quickshell/ii/modules/cheatsheet/copypad.conf\" 2>/dev/null || true";
        reader.exec(["bash", "-c", cmd]);
    }

    function _escapeLine(t) {
        return t.replace(/'/g, "'\\''");
    }

    function saveSnippets() {
        var script = "mkdir -p \"$HOME/.config/quickshell/ii/modules/cheatsheet\" && cat > \"$HOME/.config/quickshell/ii/modules/cheatsheet/copypad.conf\" <<'EOF'\n";
        for (var ci = 0; ci < columns.length; ci++) {
            var col = columns[ci];
            for (var ri = 0; ri < col.length; ri++) {
                var t = col[ri].text;
                var escaped = _escapeLine(t);
                script += escaped + "\n";
            }
            if (ci < columns.length - 1) {
                script += "\n";
            }
        }
        script += "EOF\n";
        writer.command = ["bash", "-c", script];
        writer.startDetached();
    }

    function addColumn() {
        var cols = columns.slice();
        cols.push([]);
        root.columns = cols;
        saveSnippets();
    }

    function addEntry(colIndex, text) {
        var trimmed = text.trim();
        if (trimmed.length === 0) {
            return;
        }
        var cols = columns.slice();
        cols[colIndex] = cols[colIndex].slice();
        cols[colIndex].push({ text: trimmed });
        root.columns = cols;
        saveSnippets();
    }

    function updateEntry(colIndex, rowIndex, text) {
        var trimmed = text.trim();
        if (trimmed.length === 0) {
            deleteEntry(colIndex, rowIndex);
            return;
        }
        var cols = columns.slice();
        cols[colIndex] = cols[colIndex].slice();
        cols[colIndex][rowIndex] = { text: trimmed };
        root.columns = cols;
        saveSnippets();
    }

    function deleteEntry(colIndex, rowIndex) {
        var cols = columns.slice();
        cols[colIndex] = cols[colIndex].slice();
        cols[colIndex].splice(rowIndex, 1);
        root.columns = cols;
        saveSnippets();
    }

    function copyToClipboard(text) {
        var escaped = text.replace(/'/g, "'\\''").replace(/\\/g, "\\\\");
        var cmd = "echo -n '" + escaped + "' | wl-copy";
        clipper.command = ["bash", "-c", cmd];
        clipper.startDetached();
    }

    Component.onCompleted: {
        loadSnippets();
    }

    implicitWidth: contentLayout.implicitWidth + (root.spacing * 2)
    implicitHeight: contentLayout.implicitHeight + (root.spacing * 2)

    ColumnLayout {
        id: contentLayout
        spacing: root.spacing

        anchors.centerIn: parent

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            font.family: Appearance.font.family.title
            font.pixelSize: Appearance.font.pixelSize.huge
            text: Translation.tr("Copypad")
        }

        RowLayout {
            id: columnsRow
            spacing: root.spacing
            Repeater {
                model: columns.length
                delegate: Column {
                    property int colIndex: index
                    spacing: root.spacing
                    Layout.fillWidth: true

                    Repeater {
                        model: columns[colIndex].length
                        delegate: Item {
                            id: snippetItem
                            property int rowIndex: index
                            property bool editing: false

                            implicitWidth: loader.item ? loader.item.implicitWidth : 0
                            implicitHeight: loader.item ? loader.item.implicitHeight : 0
                            width: parent.width

                            Rectangle {
                                id: itemContainer
                                anchors.fill: parent

                                radius: Appearance.rounding.large

                                color: Appearance.colors.colLayer0

                            }

                            Loader {
                                id: loader
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                sourceComponent: editing ? editRowComponent : viewRowComponent
                            }

                            Component {
                                id: viewRowComponent
                                RowLayout {
                                    spacing: root.spacing

                                    StyledText {
                                        id: snippetText
                                        text: columns[colIndex][rowIndex].text

                                        Layout.fillWidth: true
                                        Layout.leftMargin: root.spacing

                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        color: Appearance.colors.colOnLayer0
                                        elide: Text.ElideRight

                                    }

                                    RippleButton {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.full
                                        onClicked: copyToClipboard(columns[colIndex][rowIndex].text)
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            font.pixelSize: Appearance.font.pixelSize.large
                                            text: "content_copy"
                                        }
                                    }
                                    RippleButton {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.full
                                        onClicked: snippetItem.editing = true
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            font.pixelSize: Appearance.font.pixelSize.large
                                            text: "edit"
                                        }
                                    }
                                    RippleButton {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.full
                                        onClicked: deleteEntry(colIndex, rowIndex)
                                        Layout.rightMargin: root.spacing
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            font.pixelSize: Appearance.font.pixelSize.large
                                            text: "delete"
                                        }
                                    }
                                }
                            }
                            Component {
                                id: editRowComponent
                                RowLayout {
                                    spacing: root.spacing

                                    ToolbarTextField {
                                        id: editField
                                        text: columns[colIndex][rowIndex].text
                                        Layout.fillWidth: true
                                        Layout.leftMargin: root.spacing
                                        Keys.onReturnPressed: commit()
                                    }
                                    RippleButton {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.full
                                        onClicked: commit()
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            font.pixelSize: Appearance.font.pixelSize.large
                                            text: "check"
                                        }
                                    }
                                    RippleButton {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: Appearance.rounding.full
                                        onClicked: snippetItem.editing = false
                                        Layout.rightMargin: root.spacing
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            font.pixelSize: Appearance.font.pixelSize.large
                                            text: "close"
                                        }
                                    }
                                    function commit() {
                                        var val = editField.text;
                                        snippetItem.editing = false;
                                        updateEntry(colIndex, rowIndex, val);
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        height: 1
                        width: parent.width
                        color: Appearance.colors.colLayer0Border
                        visible: columns[colIndex].length > 0
                    }
                    RowLayout {
                        spacing: root.spacing
                        ToolbarTextField {
                            id: newEntryField
                            placeholderText: Translation.tr("Add new entry…")
                            Layout.fillWidth: true
                            Layout.leftMargin: root.spacing
                            Keys.onReturnPressed: addAndClear()
                            function addAndClear() {
                                var text = newEntryField.text;
                                newEntryField.text = "";
                                addEntry(colIndex, text);
                            }
                        }
                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: Appearance.rounding.full
                            onClicked: newEntryField.addAndClear()
                            Layout.rightMargin: root.spacing
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                font.pixelSize: Appearance.font.pixelSize.large
                                text: "add"
                            }
                        }
                    }
                }
            }
            RippleButton {
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: Appearance.rounding.full
                onClicked: addColumn()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.large
                    text: "add"
                }
            }
        }
    }
}
