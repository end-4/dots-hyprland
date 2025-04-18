pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
	id: root
    property alias list: notifServer.trackedNotifications

	NotificationServer {
        id: notifServer
        actionIconsSupported: true
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: true
        persistenceSupported: true

        onNotification: (notification) => {
            notification.tracked = true;
            if(!notification.time) {
                notification.time = new Date();
            }
			// root.list = [...root.list, notification];
        }
    }
}
