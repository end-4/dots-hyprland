pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * Simple to-do list manager.
 * Each item is an object with "content", "done", "date", "completedDate", and "subtasks" properties.
 */
Singleton {
    id: root
    property var filePath: Directories.todoPath
    property var list: []

    function getTodayDateString() {
        const now = new Date();
        const y = now.getFullYear();
        const m = (now.getMonth() + 1 < 10 ? '0' : '') + (now.getMonth() + 1);
        const d = (now.getDate() < 10 ? '0' : '') + now.getDate();
        return `${y}-${m}-${d}`;
    }

    function save() {
        root.list = list.slice(0);
        todoFileView.setText(JSON.stringify(root.list));
    }

    function addItem(item) {
        list.push(item);
        save();
    }

    function addTask(desc, date) {
        const item = {
            "content": desc,
            "done": false,
            "date": date || root.getTodayDateString(),
            "completedDate": null,
            "subtasks": []
        };
        addItem(item);
    }

    function markDone(index, completionDate) {
        if (index >= 0 && index < list.length) {
            list[index].done = true;
            list[index].completedDate = completionDate || root.getTodayDateString();
            if (list[index].subtasks && Array.isArray(list[index].subtasks)) {
                for (let i = 0; i < list[index].subtasks.length; i++) {
                    list[index].subtasks[i].done = true;
                }
            }
            save();
        }
    }

    function markUnfinished(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = false;
            list[index].completedDate = null;
            save();
        }
    }

    function deleteItem(index) {
        if (index >= 0 && index < list.length) {
            list.splice(index, 1);
            save();
        }
    }

    function editTask(index, newContent) {
        if (index >= 0 && index < list.length) {
            list[index].content = newContent;
            save();
        }
    }

    function addSubtask(taskIndex, subtaskContent) {
        if (taskIndex >= 0 && taskIndex < list.length) {
            const trimmed = (subtaskContent ?? "").trim();
            if (trimmed.length > 0) {
                if (!list[taskIndex].subtasks || !Array.isArray(list[taskIndex].subtasks)) {
                    list[taskIndex].subtasks = [];
                }
                list[taskIndex].subtasks.push({
                    "content": trimmed,
                    "done": false
                });
                if (list[taskIndex].done) {
                    list[taskIndex].done = false;
                    list[taskIndex].completedDate = null;
                }
                save();
            }
        }
    }

    function toggleSubtask(taskIndex, subtaskIndex) {
        if (taskIndex >= 0 && taskIndex < list.length) {
            const subtasks = list[taskIndex].subtasks;
            if (subtasks && subtaskIndex >= 0 && subtaskIndex < subtasks.length) {
                subtasks[subtaskIndex].done = !subtasks[subtaskIndex].done;
                const allDone = subtasks.length > 0 && subtasks.every(s => s.done);
                if (allDone && !list[taskIndex].done) {
                    list[taskIndex].done = true;
                    list[taskIndex].completedDate = root.getTodayDateString();
                } else if (!allDone && list[taskIndex].done) {
                    list[taskIndex].done = false;
                    list[taskIndex].completedDate = null;
                }
                save();
            }
        }
    }

    function editSubtask(taskIndex, subtaskIndex, newContent) {
        if (taskIndex >= 0 && taskIndex < list.length) {
            const subtasks = list[taskIndex].subtasks;
            if (subtasks && subtaskIndex >= 0 && subtaskIndex < subtasks.length) {
                const trimmed = (newContent ?? "").trim();
                if (trimmed.length > 0) {
                    subtasks[subtaskIndex].content = trimmed;
                    save();
                }
            }
        }
    }

    function deleteSubtask(taskIndex, subtaskIndex) {
        if (taskIndex >= 0 && taskIndex < list.length) {
            const subtasks = list[taskIndex].subtasks;
            if (subtasks && subtaskIndex >= 0 && subtaskIndex < subtasks.length) {
                subtasks.splice(subtaskIndex, 1);
                if (subtasks.length > 0 && subtasks.every(s => s.done)) {
                    list[taskIndex].done = true;
                }
                save();
            }
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
