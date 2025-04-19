pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Qt.labs.platform

Singleton {
	id: root
    property var filePath: `${StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]}/notifications/notifications.json`
    property var list: []

    signal initDone();
    signal notify(notification: var);
    signal discard(id: var);

	NotificationServer {
        id: notifServer
        // actionIconsSupported: true
        actionsSupported: true
        bodyHyperlinksSupported: true
        // bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: (notification) => {
            notification.tracked = true
            const newNotifObject = {
                "id": notification.id,
                "actions": notification.actions.map((action) => {
                    return {
                        "identifier": action.identifier,
                        "text": action.text,
                    }
                }),
                "appIcon": notification.appIcon,
                "appName": notification.appName,
                "body": notification.body,
                "image": notification.image,
                "summary": notification.summary,
                "time": Date.now(),
                "urgency": notification.urgency.toString(),
            }
			root.list = [...root.list, newNotifObject];
            root.notify(newNotifObject);
            notifFileView.setText(JSON.stringify(root.list, null, 2))
        }
    }

    function discardNotification(id) {
        const index = root.list.findIndex((notif) => notif.id === id);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex((notif) => notif.id === id);
        if (index !== -1) {
            root.list.splice(index, 1);
            notifFileView.setText(JSON.stringify(root.list, null, 2))
            triggerListChange()
        }
        if (notifServerIndex !== -1) {
            notifServer.trackedNotifications.values[notifServerIndex].dismiss()
        }
        root.discard(id);
    }

    function attemptInvokeAction(id, notifIdentifier) {
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex((notif) => notif.id === id);
        if (notifServerIndex !== -1) {
            const notifServerNotif = notifServer.trackedNotifications.values[notifServerIndex];
            const action = notifServerNotif.actions.find((action) => action.identifier === notifIdentifier);
            action.invoke()
        } else console.log("Notification not found in server: " + id)
        root.discard(id);
    }

    function triggerListChange() {
        root.list = root.list.slice(0)
    }

    function refresh() {
        notifFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    FileView {
        id: notifFileView
        path: filePath
        onLoaded: {
            const fileContents = notifFileView.text()
            root.list = JSON.parse(fileContents)
            console.log("[Notifications] File loaded")
            root.initDone()
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[Notifications] File not found, creating new file.")
                root.list = []
                notifFileView.setText(JSON.stringify(root.list))
            } else {
                console.log("[Notifications] Error loading file: " + error)
            }
        }
    }
}
