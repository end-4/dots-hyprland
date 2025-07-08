pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

/**
 * Simple to-do list manager.
 * Each item is an object with "content" and "done" properties.
 */
Singleton {
    id: root
    property var filePath: Directories.todoPath
    property var list: []
    
    function addItem(item) {
        list.push(item)
        // Reassign to trigger onListChanged
        root.list = list.slice(0)
        todoFileView.setText(JSON.stringify(root.list))
    }

    function addTask(desc) {
        const item = {
            "content": desc,
            "done": false,
        }
        addItem(item)
    }

    function moveTop(current_index) {
        var item = list[current_index]
        list.splice(current_index, 1)
        list.unshift(item)

        // Reassign to trigger onListChanged
        root.list = list.slice(0)
        todoFileView.setText(JSON.stringify(root.list))
    }

    function moveUp(current_index) {
        var item = list[current_index]

        for (var i = current_index - 1; i >= 0; i--) {
            var next_item = list[i]
            list[i] = item
            list[current_index] = next_item

            current_index = i
            if (next_item.done == item.done) {
                break
            }
        }

        // Reassign to trigger onListChanged
        root.list = list.slice(0)
        todoFileView.setText(JSON.stringify(root.list))
    }

    function moveDown(current_index) {
        var item = list[current_index]

        for (var i = current_index + 1; i < list.length; i++) {
            var next_item = list[i]
            list[i] = item
            list[current_index] = next_item

            current_index = i
            if (next_item.done == item.done) {
                break
            }
        }

        // Reassign to trigger onListChanged
        root.list = list.slice(0)
        todoFileView.setText(JSON.stringify(root.list))
    }

    function moveBottom(current_index) {
        var item = list[current_index]
        list.splice(current_index, 1)
        list.push(item)

        // Reassign to trigger onListChanged
        root.list = list.slice(0)
        todoFileView.setText(JSON.stringify(root.list))
    }

    function markDone(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = true
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function markUnfinished(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = false
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function deleteItem(index) {
        if (index >= 0 && index < list.length) {
            list.splice(index, 1)
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function refresh() {
        todoFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    FileView {
        id: todoFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            const fileContents = todoFileView.text()
            root.list = JSON.parse(fileContents)
            console.log("[To Do] File loaded")
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[To Do] File not found, creating new file.")
                root.list = []
                todoFileView.setText(JSON.stringify(root.list))
            } else {
                console.log("[To Do] Error loading file: " + error)
            }
        }
    }
}

