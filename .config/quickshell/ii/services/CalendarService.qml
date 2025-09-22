// https://github.com/AvengeMedia/DankMaterialShell/blob/master/Services/CalendarService.qml

import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import Qt.labs.platform
import qs.modules.common.functions
import qs.modules.common

Singleton {
    id: root

    property bool khalAvailable: false
    property var items: []
    property var eventsInWeek:[]

    // Process for checking khal configuration
    Process {
        id: khalCheckProcess

        command: ["khal", "list", "today"]
        running: true
        onExited: (exitCode) => {
          root.khalAvailable = (exitCode === 0);
          if(root.khalAvailable){
            interval.running = true
          }
        }
      }


      function getTasksByDate(currentDate) {
        if(!khalAvailable){
          return []
        }
        const res = [];
        
        const currentDay = currentDate.getDate();
        const currentMonth = currentDate.getMonth();
        const currentYear = currentDate.getFullYear();

        for (let i = 0; i < root.items.length; i++) {
            const taskDate = new Date(root.items[i]['startDate']);
            if (
                taskDate.getDate() === currentDay &&
                taskDate.getMonth() === currentMonth &&
                taskDate.getFullYear() === currentYear
              ) {
                res.push(root.items[i]);
              }
        }

        return res;
      }


      function getEventsInWeek() {
        if(!khalAvailable){
          return [
            {
              name: "Monday",
              events: [
                {
                  title: "Example: You need to install khal to view events",
                  start: "7:30",
                  end: "9:20",
                  color: Appearance.m3colors.m3error   
                },
              ]
            },
            {
              name: "Tuesday",
              events: []
            },
            {
              name: "Wednesday",
              events: []
            },
            {
              name: "Thursday",
              events: []
            },
            {
              name: "Friday",
              events: []
            },
            {
              name: "Saturday",
              events: []
            },
            {
              name: "Sunday",
              events: []
            }
          ]; 
        }

        const weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        const d = new Date();
        const num_day_today = d.getDay();
        let result = [];
        for (let i = 0; i < weekdays.length; i++) {
            d.setDate(d.getDate() - d.getDay() + i);
            const events = this.getTasksByDate(d);
            const name_weekday = weekdays[d.getDay()];
            let obj = {
                "name": name_weekday,
                "events": []
              };
              events.forEach((evt, i) => {
                let start_time = Qt.formatDateTime(evt["startDate"], Config.options.time.format);
                let end_time = Qt.formatDateTime(evt["endDate"], Config.options.time.format);
                let title = evt["content"];
                obj["events"].push({
                    "start": start_time,
                    "end": end_time,
                    "title": title,
                    "color": stringToColor(title)  
                });
              });
              result.push(obj)

          }
        
        return result;
      }

      function stringToColor(str) { //https://gist.github.com/0x263b/2bdd90886c2036a1ad5bcf06d6e6fb37
        let hash = 0
         if (str.length === 0) return hash;
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash);
            hash = hash & hash;
        }
        let color = '#';
        for (var i = 0; i < 3; i++) {
        let value = (hash >> (i * 8)) & 255;
            color += ('00' + value.toString(16)).substr(-2);
        }
        return color;
    }



    // Process for loading events
    Process {
      id: getEventsProcess
      running: false
        // get events for 3 months
        command: ["khal", "list", "--json", "title", "--json", "start-date", "--json" ,"start-time", "--json" ,"end-time",   Qt.formatDate(new Date(), "dd/MM/yyyy") ,Qt.formatDate((() => { let d = new Date(); d.setMonth(d.getMonth() + 3); return d; })(), "dd/MM/yyyy")]
        stdout: StdioCollector {

          onStreamFinished:{
            let events = []
            let lines = this.text.split('\n')
             for(let line of lines){
               line = line.trim()
               if (!line || line === "[]")
                    continue
                let dayEvents = JSON.parse(line)
                for(let event of dayEvents){
                  let startDateParts = event['start-date'].split('/')
                  let startTimeParts = event['start-time'] 
                      ? event['start-time'].split(':').map(Number) 
                      : [0, 0];

                  let endTimeParts = event['end-time'] 
                      ? event['end-time'].split(':').map(Number) 
                      : [0, 0];
             
                  
                  let startDate = new Date(parseInt(startDateParts[2]),
                                           parseInt(startDateParts[1]) - 1,
                                           parseInt(startDateParts[0]),
                                           parseInt(startTimeParts[0]), 
                                           parseInt(startTimeParts[1]))
                  
                  let endDate = new Date(parseInt(startDateParts[2]),
                                           parseInt(startDateParts[1]) - 1,
                                           parseInt(startDateParts[0]),
                                           parseInt(endTimeParts[0]), 
                                           parseInt(endTimeParts[1]))

                  events.push({
                      "content": event['title'],
                      "startDate": startDate,
                      "endDate": endDate,
                      "isTodo":false
                  })
                }
              }
              root.items = events
              root.eventsInWeek = root.getEventsInWeek()
          }
    
        }
      }

      Timer {
        id: interval
        running: false
        interval:10
        repeat: true
        onTriggered: {
          getEventsProcess.running = true
          this.interval =    Config.options?.resources?.updateInterval ?? 3000
                   
        }
    }



      
      Process {
        id: khalAddTaskProcess
        running: false
      }



      function addItem(item){
        let title =  item['content']
        let formattedDate = Qt.formatDate(item['date'], "dd/MM/yyyy")
        khalAddTaskProcess.command = ["khal", "new", formattedDate, title]
        khalAddTaskProcess.running = true
      }


    Process {
        id: khalRemoveProcess
        running: false
      }

      function removeItem(item){
        let taskToDelete =  item['content']

        khalRemoveProcess.command = [ // currently only this hack is possible to delte without interactive shell issue:https://github.com/pimutils/khal/issues/603
          "sqlite3",
          String(StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]).replace("file://", "") + "/.local/share/khal/khal.db",
          "DELETE FROM events WHERE item LIKE '%SUMMARY:" + taskToDelete + "%';"
          ]

        
          khalRemoveProcess.running = true
          console.log(khalRemoveProcess.command)


    }
}
