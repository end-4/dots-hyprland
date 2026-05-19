pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell;
import qs.services
import Quickshell.Io;
import QtQuick;
import qs.modules.common.functions


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


    function getTasksByDate(currentDate) {
        const res = [];
        
        const currentDay = currentDate.getDate();
        const currentMonth = currentDate.getMonth();
        const currentYear = currentDate.getFullYear();

        for (let i = 0; i < root.list.length; i++) {
            const taskDate = new Date(root.list[i]['date']);
            if (
                taskDate.getDate() === currentDay &&
                taskDate.getMonth() === currentMonth &&
                taskDate.getFullYear() === currentYear
              ) {
                res.push(root.list[i]);
              }
        }

        return res;
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

            if(CalendarService.khalAvailable){ //kahl does not support saving mark
              return
            }
            todoFileView.setText(JSON.stringify(root.list))
        }
    }

    function deleteItem(index) {
      if (index >= 0 && index < list.length) {
            let item = list[index]
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

            for (let i=0; i< root.list.length; i++){ //parse date as date object
              root.list[i]['date'] = new Date(root.list[i]['date'])
            }

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

