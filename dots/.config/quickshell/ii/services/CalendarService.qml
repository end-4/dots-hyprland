// https://github.com/AvengeMedia/DankMaterialShell/blob/master/Services/CalendarService.qml

import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import Qt.labs.platform
import qs.modules.common.functions
import qs.modules.common

Singleton {
    id: root

    property bool khalAvailable: false
    property var events: []
    property var weekdays: [
          Translation.tr("Sunday"), 
          Translation.tr("Monday"), 
          Translation.tr("Tuesday"), 
          Translation.tr("Wednesday"), 
          Translation.tr("Thursday"), 
          Translation.tr("Friday"), 
          Translation.tr("Saturday"),

        ];
    property var sortedWeekdays: root.weekdays.map((_, i) => weekdays[(i+Config.options.time.firstDayOfWeek+1)%7]);
    property var eventsInWeek: [
            {
              name:  sortedWeekdays[0],
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
              name: sortedWeekdays[1],
              events: []
            },
            {
              name: sortedWeekdays[2],
              events: []
            },
            {
              name: sortedWeekdays[3],
              events: []
            },
            {
              name: sortedWeekdays[4],
              events: []
            },
            {
              name: sortedWeekdays[5],
              events: []
            },
            {
              name: sortedWeekdays[6],
              events: []
            }
          ]
 

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

        for (let i = 0; i < root.events.length; i++) {
            const taskDate = new Date(root.events[i]['startDate']);
            if (
                taskDate.getDate() === currentDay &&
                taskDate.getMonth() === currentMonth &&
                taskDate.getFullYear() === currentYear
              ) {
                res.push(root.events[i]);
              }
        }

        return res;
      }


      function getEventsInWeek() {
        



        const d = new Date();
        const num_day_today = d.getDay();
        let result = [];
        for (let i = 0; i < root.weekdays.length; i++) {
            const dayOffset = (i + Config.options.time.firstDayOfWeek+1); 
            d.setDate(d.getDate() - d.getDay() + dayOffset %7);
            const events = this.getTasksByDate(d);
            const name_weekday = root.weekdays[d.getDay()];
            let obj = {
                "name": name_weekday,
                "events": []
              };
              events.forEach((evt, i) => {
                let start_time = Qt.formatDateTime(evt["startDate"], "hh:mm");
                let end_time = Qt.formatDateTime(evt["endDate"], "hh:mm");
                let title = evt["content"];
                obj["events"].push({
                    "start": start_time,
                    "end": end_time,
                    "title": title,
                    "color": evt['color'] 
                });
              });
              result.push(obj)

          }
        
        return result;
      }

    // Process for loading events
    Process {
      id: getEventsProcess
      running: false
        // get events for 3 months
        command: ["khal", "list", "--json", "title", "--json", "start-date", "--json" ,"start-time", "--json" ,"end-time",    Qt.formatDate((() => { let d = new Date(); d.setMonth(d.getMonth() - 3); return d; })(), "dd/MM/yyyy") ,Qt.formatDate((() => { let d = new Date(); d.setMonth(d.getMonth() + 3); return d; })(), "dd/MM/yyyy")]
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
                      : [23, 59]; // event is the whole day if start and end time are not set
             
                  
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
                      "color": ColorUtils.stringToColor(event['title']),  
                  })
                }
              }
              root.events = events
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
