import QtQuick 2.15

Item {
    property int totalIndex // The index for both lists together (as stored in file)
    property int listIndex // The index in its own unfinished/done list
    property bool done
    property string currentText
}