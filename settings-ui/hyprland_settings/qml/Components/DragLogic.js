// hyprland-settings/qml/Components/DragLogic.js

// --- Утилиты ---

// Находит Repeater-делегат по его ID
function findDelegateById(repeater, id) {
    for (var i = 0; i < repeater.count; i++) {
        var item = repeater.itemAt(i);
        if (item && item.monitorId === id) {
            return item;
        }
    }
    return null;
}

// Проверяет наличие коллизий между делегатами
function checkCollision(item, newX, newY, repeater, monitors) {
    const itemRect = {
        x: newX,
        y: newY,
        width: item.visualWidth,
        height: item.visualHeight
    };

    for (var i = 0; i < repeater.count; i++) {
        const other = repeater.itemAt(i);
        if (!other || other.monitorId === item.monitorId) continue;
        
        // Найдем монитор в массиве по ID
        var monitorData = null;
        for (var j = 0; j < monitors.length; j++) {
            if (monitors[j] && monitors[j].id === other.monitorId) {
                monitorData = monitors[j];
                break;
            }
        }
        
        if (monitorData && monitorData.disabled) continue;

        const otherRect = {
            x: other.x,
            y: other.y,
            width: other.visualWidth,
            height: other.visualHeight
        };

        if (itemRect.x < otherRect.x + otherRect.width &&
            itemRect.x + itemRect.width > otherRect.x &&
            itemRect.y < otherRect.y + otherRect.height &&
            itemRect.y + itemRect.height > otherRect.y) {
            return true;
        }
    }
    return false;
}

// --- Основная логика прилипания ---

// Находит наилучшую точку прилипания для элемента
function findBestSnap(item, repeater, snapThreshold, canvas) {
    const bestSnap = {
        x: item.x,
        y: item.y,
        bestDistX: snapThreshold + 1,
        bestDistY: snapThreshold + 1,
        constraintX: null,
        constraintY: null
    };
    
    const itemWidth = item.visualWidth;
    const itemHeight = item.visualHeight;

    for (var i = 0; i < repeater.count; i++) {
        const other = repeater.itemAt(i);
        if (!other || other.monitorId === item.monitorId) continue;
        
        const otherWidth = other.visualWidth;
        const otherHeight = other.visualHeight;

        // Проверка по оси X - прилипание к левой/правой грани или центрирование
        const xTargets = [
            { pos: other.x - itemWidth, edge: "right-left", centerY: other.y + otherHeight / 2 - itemHeight / 2 },
            { pos: other.x + otherWidth, edge: "left-right", centerY: other.y + otherHeight / 2 - itemHeight / 2 },
            { pos: other.x + otherWidth / 2 - itemWidth / 2, edge: "center-center", centerY: other.y + otherHeight / 2 - itemHeight / 2 }
        ];
        
        for (const target of xTargets) {
            const dist = Math.abs(item.x - target.pos);
            if (dist <= snapThreshold && dist < bestSnap.bestDistX) {
                bestSnap.bestDistX = dist;
                bestSnap.x = target.pos;
                bestSnap.constraintX = { 
                    id: other.monitorId, 
                    edge: target.edge,
                    centerY: target.centerY,
                    snapPos: target.pos
                };
            }
        }

        // Проверка по оси Y - прилипание к верхней/нижней грани или центрирование
        const yTargets = [
            { pos: other.y - itemHeight, edge: "bottom-top", centerX: other.x + otherWidth / 2 - itemWidth / 2 },
            { pos: other.y + otherHeight, edge: "top-bottom", centerX: other.x + otherWidth / 2 - itemWidth / 2 },
            { pos: other.y + otherHeight / 2 - itemHeight / 2, edge: "center-center", centerX: other.x + otherWidth / 2 - itemWidth / 2 }
        ];
        
        for (const target of yTargets) {
            const dist = Math.abs(item.y - target.pos);
            if (dist <= snapThreshold && dist < bestSnap.bestDistY) {
                bestSnap.bestDistY = dist;
                bestSnap.y = target.pos;
                bestSnap.constraintY = { 
                    id: other.monitorId, 
                    edge: target.edge,
                    centerX: target.centerX,
                    snapPos: target.pos
                };
            }
        }
    }
    
    return bestSnap;
}

// Вычисляет позицию с учетом привязок
function calculateConstrainedPosition(item, mouseDrivenPos, constraintX, constraintY, wasJustSnapped, repeater) {
    let finalPos = Qt.point(mouseDrivenPos.x, mouseDrivenPos.y);

    if (constraintX && constraintY) { // Привязка к углу
        finalPos.x = constraintX.snapPos;
        finalPos.y = constraintY.snapPos;
    } else if (constraintX) { // Привязка к вертикальной грани
        finalPos.x = constraintX.snapPos;
        if (wasJustSnapped || constraintX.edge === "center-center") {
            finalPos.y = constraintX.centerY; // Центрируем при первой привязке
        } else {
            // Разрешаем скольжение по оси Y
            const targetMonitor = findDelegateById(repeater, constraintX.id);
            if (targetMonitor) {
                const targetTop = targetMonitor.y;
                const targetBottom = targetMonitor.y + targetMonitor.visualHeight;
                const itemHeight = item.visualHeight;
                // Ограничиваем скольжение границами целевого монитора с небольшим запасом
                const minY = targetTop - itemHeight + 10;
                const maxY = targetBottom - 10;
                finalPos.y = Math.max(minY, Math.min(maxY, mouseDrivenPos.y));
            } else {
                finalPos.y = mouseDrivenPos.y; // Резервный вариант
            }
        }
    } else if (constraintY) { // Привязка к горизонтальной грани
        finalPos.y = constraintY.snapPos;
        if (wasJustSnapped || constraintY.edge === "center-center") {
            finalPos.x = constraintY.centerX; // Центрируем при первой привязке
        } else {
            // Разрешаем скольжение по оси X
            const targetMonitor = findDelegateById(repeater, constraintY.id);
            if (targetMonitor) {
                const targetLeft = targetMonitor.x;
                const targetRight = targetMonitor.x + targetMonitor.visualWidth;
                const itemWidth = item.visualWidth;
                // Ограничиваем скольжение границами целевого монитора с небольшим запасом
                const minX = targetLeft - itemWidth + 10;
                const maxX = targetRight - 10;
                finalPos.x = Math.max(minX, Math.min(maxX, mouseDrivenPos.x));
            } else {
                finalPos.x = mouseDrivenPos.x; // Резервный вариант
            }
        }
    }

    return finalPos;
}

// Проверяет, нужно ли оторвать элемент от привязки
function shouldBreakConstraint(mouseDrivenPos, constraintPos, threshold) {
    return Math.abs(mouseDrivenPos - constraintPos) > threshold;
}