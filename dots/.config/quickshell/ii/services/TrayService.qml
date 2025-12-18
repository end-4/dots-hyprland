pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Singleton {
    id: root

    property bool smartTray: Config.options.tray.filterPassive
    
    // Check if item matches any stored pin ID (handles both new format and legacy)
    function isItemPinnedInConfig(item) {
        if (!Config.ready || !item) return false;
        var uniqueId = getUniqueItemId(item);
        // Check current unique ID format
        if (Config.options.tray.pinnedItems.includes(uniqueId)) return true;
        // For backward compatibility: check if item.id alone is in the list
        // but only if there's exactly one item with this id (to avoid group pinning)
        var itemsWithSameId = SystemTray.items.values.filter(i => i.id === item.id);
        if (itemsWithSameId.length === 1 && Config.options.tray.pinnedItems.includes(item.id)) {
            return true;
        }
        return false;
    }
    
    property list<var> itemsInUserList: SystemTray.items.values.filter(i => {
        if (smartTray && i.status === Status.Passive) return false;
        return isItemPinnedInConfig(i);
    })
    property list<var> itemsNotInUserList: SystemTray.items.values.filter(i => {
        if (smartTray && i.status === Status.Passive) return false;
        return !isItemPinnedInConfig(i);
    })

    property bool invertPins: Config.options.tray.invertPinnedItems
    property list<var> pinnedItems: invertPins ? itemsNotInUserList : itemsInUserList
    property list<var> unpinnedItems: invertPins ? itemsInUserList : itemsNotInUserList

    function getTooltipForItem(item) {
        var result = item.tooltipTitle.length > 0 ? item.tooltipTitle
                : (item.title.length > 0 ? item.title : item.id);
        if (item.tooltipDescription.length > 0) result += " • " + item.tooltipDescription;
        if (Config.options.tray.showItemId) result += "\n[" + item.id + "]";
        return result;
    }

    // Get unique identifier for an item instance
    // Uses index to ensure each item instance has independent pin state
    function getUniqueItemId(item) {
        if (!item) return "";
        var index = SystemTray.items.values.indexOf(item);
        // Combine id with index to make it unique per instance
        // This ensures items with same id but different positions are tracked separately
        if (index >= 0) {
            return item.id + "::" + index;
        }
        // Fallback: use id only if item not found in list
        return item.id;
    }
    
    // Helper to find item by stored unique ID (for backward compatibility)
    function findItemByStoredId(storedId) {
        // Try to parse id:index format
        var parts = storedId.split("::");
        if (parts.length === 2) {
            var itemId = parts[0];
            var storedIndex = parseInt(parts[1]);
            // Find item with matching id at the stored index
            var items = SystemTray.items.values.filter(i => i.id === itemId);
            if (storedIndex >= 0 && storedIndex < items.length) {
                return items[storedIndex];
            }
        }
        // Fallback: try to find by id only
        var itemsById = SystemTray.items.values.filter(i => i.id === storedId);
        return itemsById.length > 0 ? itemsById[0] : null;
    }

    // Pinning - now uses unique identifier per item instance
    function pin(item) {
        var uniqueId = getUniqueItemId(item);
        var pins = Config.options.tray.pinnedItems;
        if (pins.includes(uniqueId)) return;
        Config.options.tray.pinnedItems.push(uniqueId);
    }
    function unpin(item) {
        var uniqueId = getUniqueItemId(item);
        Config.options.tray.pinnedItems = Config.options.tray.pinnedItems.filter(id => id !== uniqueId);
    }
    function togglePin(item) {
        var uniqueId = getUniqueItemId(item);
        var pins = Config.options.tray.pinnedItems;
        if (pins.includes(uniqueId)) {
            unpin(item)
        } else {
            pin(item)
        }
    }
    
    // Check if an item is pinned (by unique identifier)
    function isItemPinned(item) {
        return isItemPinnedInConfig(item);
    }

}
