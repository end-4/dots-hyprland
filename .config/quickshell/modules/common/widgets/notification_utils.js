function guessMessageType(summary) {
    const keywordsToTypes = {
        'reboot': 'restart_alt',
        'recording': 'screen_record',
        'battery': 'power',
        'power': 'power',
        'screenshot': 'screenshot_monitor',
        'welcome': 'waving_hand',
        'time': 'scheduleb',
        'installed': 'download',
        'update': 'update',
        'ai response': 'neurology',
        'startswith:file': 'folder_copy', // Declarative startsWith check
    };

    const lowerSummary = summary.toLowerCase();

    for (const [keyword, type] of Object.entries(keywordsToTypes)) {
        if (keyword.startsWith('startswith:')) {
            const startsWithKeyword = keyword.replace('startswith:', '');
            if (lowerSummary.startsWith(startsWithKeyword)) {
                return type;
            }
        } else if (lowerSummary.includes(keyword)) {
            return type;
        }
    }

    return 'chat';
}

// const getFriendlyNotifTimeString = (timeObject) => {
//     const messageTime = GLib.DateTime.new_from_unix_local(timeObject);
//     const oneMinuteAgo = GLib.DateTime.new_now_local().add_seconds(-60);
//     if (messageTime.compare(oneMinuteAgo) > 0)
//         return getString('Now');
//     else if (messageTime.get_day_of_year() == GLib.DateTime.new_now_local().get_day_of_year())
//         return messageTime.format(userOptions.time.format);
//     else if (messageTime.get_day_of_year() == GLib.DateTime.new_now_local().get_day_of_year() - 1)
//         return getString('Yesterday');
//     else
//         return messageTime.format(userOptions.time.dateFormat);
// }

const getFriendlyNotifTimeString = (timeObject) => {
    const messageTime = new Date(timeObject * 1000);
    const now = new Date();
    const oneMinuteAgo = new Date(now.getTime() - 60000);

    if (messageTime > oneMinuteAgo) {
        return 'Now';
    }
    else if (messageTime.toDateString() === now.toDateString()) {
        return messageTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
    else if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString()) {
        return 'Yesterday';
    }
    else {
        return messageTime.toLocaleDateString();
    }
};
