
/**
 * @param { string } summary 
 * @returns { string }
 */
function findSuitableMaterialSymbol(summary = "") {
    const defaultType = 'chat';
    if(summary.length === 0) return defaultType;

    const keywordsToTypes = {
        'reboot': 'restart_alt',
        'record': 'screen_record',
        'battery': 'power',
        'power': 'power',
        'screenshot': 'screenshot_monitor',
        'welcome': 'waving_hand',
        'time': 'scheduleb',
        'installed': 'download',
        'configuration reloaded': 'reset_wrench',
        'config': 'reset_wrench',
        'update': 'update',
        'ai response': 'neurology',
        'control': 'settings',
        'upsca': 'compare',
        'install': 'deployed_code_update',
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

    return defaultType;
}

/**
 * @param { number | string | Date } timestamp 
 * @returns { string }
 */
const getFriendlyNotifTimeString = (timestamp) => {
    if (!timestamp) return '';
    const messageTime = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - messageTime.getTime();

    // Less than 1 minute
    if (diffMs < 60000) 
        return 'Now';
    
    // Same day - show relative time
    if (messageTime.toDateString() === now.toDateString()) {
        const diffMinutes = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        
        if (diffHours > 0) {
            return `${diffHours}h`;
        } else {
            return `${diffMinutes}m`;
        }
    }
    
    // Yesterday
    if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString()) 
        return 'Yesterday';
    
    // Older dates
    return Qt.formatDateTime(messageTime, "MMMM dd");
};