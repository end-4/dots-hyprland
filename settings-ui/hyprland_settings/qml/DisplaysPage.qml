// hyprland-settings/qml/DisplaysPage.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0
import Components 1.0
import Controls 1.0
import "Components/DragLogic.js" as DragLogic

Rectangle {
    id: root
    color: Theme.surfaceContainerLow

    property var currentMonitors: []
    property int selectedMonitorId: -1
    property real visualScale: 0.1
    property bool _internalUpdate: false

    property bool hasSelection: selectedMonitorId !== -1 && findMonitorIndex(selectedMonitorId) !== -1

    property int currentMonitorIndex: -1
    property var currentMonitor: null

    property int snapThreshold: 25
    property int breakawayThreshold: 40
    property real _canvasPadding: 100
    property point canvasCenter: Qt.point(canvas.width / 2, canvas.height / 2)


    ListModel { id: resolutionsModel }
    ListModel { id: refreshRatesModel }
    ListModel { id: mirrorMonitorsModel }
    property var availableModesMap: ({})

    onSelectedMonitorIdChanged: updateCurrentMonitor()
    onCurrentMonitorsChanged: {
        updateCurrentMonitor();
        Qt.callLater(function() { root.updateVisualBounds(); });
    }

    onCurrentMonitorChanged: {
        if (_internalUpdate) return;
        if (currentMonitor) {
            updateAvailableModes();
            updateMirrorModel();
        }
    }


    function updateMirrorModel() {
        _internalUpdate = true;
        mirrorMonitorsModel.clear();
        mirrorMonitorsModel.append({ text: qsTr("None"), name: "" });
        if (!currentMonitor) {
             _internalUpdate = false;
             return;
        }

        for (var i = 0; i < currentMonitors.length; i++) {
            var mon = currentMonitors[i];
            if (mon.id !== selectedMonitorId) {
                mirrorMonitorsModel.append({ text: mon.name, name: mon.name });
            }
        }

        var found = false;
        for(var i = 0; i < mirrorMonitorsModel.count; ++i) {
            if(mirrorMonitorsModel.get(i).name === currentMonitor.mirrorSource) {
                mirrorCombo.currentIndex = i;
                found = true;
                break;
            }
        }
        if(!found) mirrorCombo.currentIndex = 0;
        _internalUpdate = false;
    }


    function updateCurrentMonitor() {
        var idx = findMonitorIndex(selectedMonitorId)
        currentMonitorIndex = idx
        currentMonitor = idx !== -1 ? currentMonitors[idx] : null
    }

    function updateRefreshRateModel() {
        if (!root.currentMonitor || resolutionCombo.currentIndex < 0) return;
        refreshRatesModel.clear();
        var selectedResolution = resolutionsModel.get(resolutionCombo.currentIndex).text;
        var rates = availableModesMap[selectedResolution] || [];
        for (var i = 0; i < rates.length; i++) refreshRatesModel.append({ text: rates[i] + " Hz" });

        _internalUpdate = true;
        var currentRefreshText = parseFloat(root.currentMonitor.refreshRate).toFixed(2) + " Hz";
        var resolutionMatches = selectedResolution === (Math.round(root.currentMonitor.width) + "x" + Math.round(root.currentMonitor.height));
        var foundRate = false;
        if (resolutionMatches) {
            for (var i = 0; i < refreshRatesModel.count; i++) {
                if (refreshRatesModel.get(i).text === currentRefreshText) {
                    refreshRateCombo.currentIndex = i;
                    foundRate = true; break;
                }
            }
        }
        if (!foundRate && refreshRatesModel.count > 0) refreshRateCombo.currentIndex = 0;
        _internalUpdate = false;
    }

    function updateAvailableModes() {
        resolutionsModel.clear();
        refreshRatesModel.clear();
        availableModesMap = {};

        if (!currentMonitor || !currentMonitor.availableModes) return;

        for (var i = 0; i < currentMonitor.availableModes.length; i++) {
            var mode = currentMonitor.availableModes[i];
            var parts = mode.split('@');
            var resolution = parts[0];
            var refresh = parseFloat(parts[1]).toFixed(2);
            if (!availableModesMap[resolution]) {
                availableModesMap[resolution] = [];
            }
            availableModesMap[resolution].push(refresh);
        }

        var uniqueResolutions = Object.keys(availableModesMap);
        for (var i = 0; i < uniqueResolutions.length; i++) {
            resolutionsModel.append({ text: uniqueResolutions[i] });
        }
        
        _internalUpdate = true;
        var currentResText = Math.round(currentMonitor.width) + "x" + Math.round(currentMonitor.height);
        var found = false;
        for (var i = 0; i < resolutionsModel.count; i++) {
            if (resolutionsModel.get(i).text === currentResText) {
                resolutionCombo.currentIndex = i;
                found = true;
                break;
            }
        }
        if (!found && resolutionsModel.count > 0) {
            resolutionCombo.currentIndex = 0;
        }
        _internalUpdate = false;
        if (resolutionCombo.currentIndex !== -1) {
            updateRefreshRateModel();
        }
    }


    Component.onCompleted: {
        updateCurrentMonitor()
        DisplaysBridge.load_monitors()
    }

    Connections {
        target: DisplaysBridge
        function onMonitorsChanged() {
            var newMonitors = DisplaysBridge.getMonitors()
            for (var i = 0; i < newMonitors.length; i++) {
           
                 var mon = newMonitors[i];
                if (!mon) continue;

                if (mon.disabled === undefined) mon.disabled = !mon.active;
                if (mon.transform === undefined) mon.transform = 0;
                if (mon.availableModes === undefined) mon.availableModes = [];
                if (mon.x === undefined) mon.x = 0;
                if (mon.y === undefined) mon.y = 0;
                if (mon.width === undefined) mon.width = 1920;
                if (mon.height === undefined) mon.height = 1080;
                if (mon.refreshRate === undefined) mon.refreshRate = 60.0;
                if (mon.scale === undefined) mon.scale = 1.0;
                if (mon.name === undefined) mon.name = "Unknown";
                if (mon.mirrorSource === undefined) mon.mirrorSource = "";
                if (mon.vrr === undefined) mon.vrr = 0;
                if (mon.bitdepth === undefined) mon.bitdepth = 8;
                if (mon.colorManagement === undefined) mon.colorManagement = "auto";
                if (mon.sdrBrightness === undefined) mon.sdrBrightness = 1.0;
                if (mon.sdrSaturation === undefined) mon.sdrSaturation = 1.0;
                if (mon.reservedTop === undefined) mon.reservedTop = 0;
                if (mon.reservedBottom === undefined) mon.reservedBottom = 0;
                if (mon.reservedLeft === undefined) mon.reservedLeft = 0;
                if (mon.reservedRight === undefined) mon.reservedRight = 0;
            }
            currentMonitors = newMonitors;
            var isCurrentSelectionValid = false;
            for (var j = 0; j < currentMonitors.length; j++) {
                if (currentMonitors[j] && currentMonitors[j].id === selectedMonitorId) {
                    isCurrentSelectionValid = true;
                    break;
                }
            }

            if (!isCurrentSelectionValid && currentMonitors.length > 0) {
                selectedMonitorId = currentMonitors[0] ?
                currentMonitors[0].id : -1;
            } else if (currentMonitors.length === 0) {
                selectedMonitorId = -1;
            }
        }
    }

    function updateVisualBounds() {
        if (view.width <= 0 || view.height <= 0) {
            return;
        }

        if (currentMonitors.length === 0) {
            visualScale = 0.1;
            return;
        }

        if (currentMonitors.length === 1) {
            var mon = currentMonitors[0];
            var isSideways = (mon.transform % 4) % 2 !== 0;
            var w = isSideways ? mon.height : mon.width;
            var h = isSideways ? mon.width : mon.height;

            if (w <= 0 || h <= 0) return;
            var scaleX = (view.width - _canvasPadding) / w;
            var scaleY = (view.height - _canvasPadding) / h;
            visualScale = Math.min(scaleX, scaleY) * 0.9;

            var centerX = mon.x + w / 2;
            var centerY = mon.y + h / 2;

            view.contentX = (centerX * visualScale) - (view.width / 2) + canvasCenter.x;
            view.contentY = (centerY * visualScale) - (view.height / 2) + canvasCenter.y;
        } else if (currentMonitors.length > 1) {
            var minX = Infinity, minY = Infinity;
            var maxX = -Infinity, maxY = -Infinity;

            for (var i = 0; i < currentMonitors.length; i++) {
                var mon = currentMonitors[i];
                var isSideways = (mon.transform % 4) % 2 !== 0;
                var w = isSideways ? mon.height : mon.width;
                var h = isSideways ? mon.width : mon.height;

                minX = Math.min(minX, mon.x);
                minY = Math.min(minY, mon.y);
                maxX = Math.max(maxX, mon.x + w);
                maxY = Math.max(maxY, mon.y + h);
            }

            var totalWidth = maxX - minX;
            var totalHeight = maxY - minY;
            if (totalWidth <= 0 || totalHeight <= 0) return;
            var scaleX = (view.width - _canvasPadding) / totalWidth;
            var scaleY = (view.height - _canvasPadding) / totalHeight;
            visualScale = Math.min(scaleX, scaleY) * 0.95;

            var centerX = minX + totalWidth / 2;
            var centerY = minY + totalHeight / 2;

            view.contentX = (centerX * visualScale) - (view.width / 2) + canvasCenter.x;
            view.contentY = (centerY * visualScale) - (view.height / 2) + canvasCenter.y;
        }
    }


    function findMonitorIndex(id) {
        if (id === -1) return -1;
        for (var i = 0; i < currentMonitors.length; i++) {
            if (currentMonitors[i] && currentMonitors[i].id === id) return i;
        }
        return -1;
    }

    function forceMonitorsUpdate() {
        _internalUpdate = true;
        root.currentMonitors = root.currentMonitors.slice();
        Qt.callLater(function() { _internalUpdate = false; });
    }

    function applySettings() {
        var configs = [];
        for (var i = 0; i < currentMonitors.length; i++) {
            var mon = currentMonitors[i];
            if (!mon) continue;

            if (mon.disabled) {
                configs.push(mon.name + ",disable");
                continue;
            }

            var parts = [];
            parts.push(mon.name);
            var refreshRateValue = parseFloat(mon.refreshRate).toFixed(2);
            parts.push(`${Math.round(mon.width)}x${Math.round(mon.height)}@${refreshRateValue}`);
            parts.push(`${Math.round(mon.x)}x${Math.round(mon.y)}`);
            parts.push(mon.scale.toFixed(2));

            if (mon.transform > 0) {
                parts.push("transform", mon.transform);
            }
            if (mon.mirrorSource && mon.mirrorSource !== "") {
                parts.push("mirror", mon.mirrorSource);
            }
            if (mon.vrr > 0) {
                parts.push("vrr", mon.vrr);
            }
            if (mon.bitdepth === 10) {
                parts.push("bitdepth", 10);
            }
            if (mon.colorManagement && mon.colorManagement !== "auto" && mon.colorManagement !== "") {
                parts.push("cm", mon.colorManagement);
                if (mon.colorManagement === 'hdr' || mon.colorManagement === 'hdredid') {
                    parts.push("sdrbrightness", parseFloat(mon.sdrBrightness).toFixed(2));
                    parts.push("sdrsaturation", parseFloat(mon.sdrSaturation).toFixed(2));
                }
            }

            configs.push(parts.join(','));
            if (mon.reservedTop > 0 || mon.reservedBottom > 0 || mon.reservedLeft > 0 || mon.reservedRight > 0) {
                var reservedParts = [];
                reservedParts.push(mon.name);
                reservedParts.push("addreserved");
                reservedParts.push(Math.round(mon.reservedTop));
                reservedParts.push(Math.round(mon.reservedBottom));
                reservedParts.push(Math.round(mon.reservedLeft));
                reservedParts.push(Math.round(mon.reservedRight));
                configs.push(reservedParts.join(','));
            }
        }
        DisplaysBridge.applyMonitorSettings(configs);
    }
    
    // Функции проверки коллизий, которые используются в DragLogic.js
    function checkCollisionJS(item, newX, newY) {
        return DragLogic.checkCollision(item, newX, newY, monitorRepeater, currentMonitors);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true;
            Layout.preferredHeight: 80
            color: Theme.surfaceContainer
            RowLayout {
                anchors.fill: parent;
                anchors.leftMargin: 16; anchors.rightMargin: 16
                Item { Layout.fillWidth: true }
                StyledButton { text: qsTr("Apply Settings");
                    highlighted: true; enabled: currentMonitors.length > 0; onClicked: applySettings() }
            }
        }

        RowLayout {
            Layout.fillWidth: true;
            Layout.fillHeight: true

            Flickable {
                id: view
                Layout.fillWidth: true;
                Layout.fillHeight: true
                contentWidth: 8000;
                contentHeight: 8000; clip: true
                interactive: false

                Item {
                    id: canvas
                    width: view.contentWidth;
                    height: view.contentHeight

                    Rectangle { id: verticalSnapLine;
                        width: 2; height: canvas.height; color: Theme.primary; visible: false; y: 0 }
                    Rectangle { id: horizontalSnapLine;
                        width: canvas.width; height: 2; color: Theme.primary; visible: false; x: 0 }

                    Repeater {
                        id: monitorRepeater
                        model: currentMonitors
                        
                        delegate: Item {
                            id: monitorDelegate
                            property int monitorId: modelData.id
                            property bool isSelected: selectedMonitorId === monitorId
                            property bool isDragging: false
                            property var constraintX: null
                            property var constraintY: null
                            property point dragStartPos: Qt.point(0,0)
                            property point initialMousePos: Qt.point(0, 0)
                            
                            readonly property bool isSideways: (modelData.transform % 4) % 2 !== 0
                            readonly property real visualWidth: isSideways ? height : width
                            readonly property real visualHeight: isSideways ? width : height
                            
                            x: canvasCenter.x + modelData.x * visualScale
                            y: canvasCenter.y + modelData.y * visualScale
    
                            width: (modelData.width / modelData.scale) * visualScale
                            height: (modelData.height / modelData.scale) * visualScale
                            
                            transform: [
                                Rotation {
                                    origin.x: width / 2;
                                    origin.y: height / 2
                                    angle: (modelData.transform < 4) ? (modelData.transform * 90) : ((modelData.transform - 4) * 90)
                                    Behavior on angle { SpringAnimation { spring: 2; damping: 0.4 } }
                                },
                                Scale {
                                    origin.x: width / 2; origin.y: height / 2
                                    xScale: (modelData.transform >= 4) ? -1 : 1
                                }
                            ]
                            
                            Rectangle {
                                anchors.fill: parent
                                color: modelData.disabled ? Theme.outline : Theme.surfaceContainerHigh
                                border.width: isSelected ? 3 : 1
                                border.color: isSelected ? Theme.primary : Theme.outline
                                radius: Theme.radius
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.name
                                color: isSelected ? Theme.primary : Theme.text
                                font.pixelSize: 14
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: selectedMonitorId = monitorId
                                drag { target: monitorDelegate; axis: Drag.XAndYAxis; }
                                enabled: currentMonitors.length > 1

                                onPressed: function(mouse) {
                                    isDragging = true;
                                    dragStartPos = Qt.point(parent.x, parent.y);
                                    initialMousePos = Qt.point(mouse.x, mouse.y);
                                    monitorDelegate.constraintX = null;
                                    monitorDelegate.constraintY = null;
                                }

                                onPositionChanged: function(mouse) {
                                    if (!drag.active) return;

                                    const mouseDrivenPos = Qt.point(
                                        dragStartPos.x + mouse.x - initialMousePos.x,
                                        dragStartPos.y + mouse.y - initialMousePos.y
                                    );

                                    const prevConstraintX = monitorDelegate.constraintX;
                                    const prevConstraintY = monitorDelegate.constraintY;

                                    const snapInfo = DragLogic.findBestSnap(parent, monitorRepeater, snapThreshold, canvas);

                                    if (prevConstraintX && DragLogic.shouldBreakConstraint(mouseDrivenPos.x, prevConstraintX.snapPos, breakawayThreshold)) {
                                        monitorDelegate.constraintX = null;
                                    }
                                    if (prevConstraintY && DragLogic.shouldBreakConstraint(mouseDrivenPos.y, prevConstraintY.snapPos, breakawayThreshold)) {
                                        monitorDelegate.constraintY = null;
                                    }

                                    if (!monitorDelegate.constraintX && snapInfo.constraintX) {
                                        monitorDelegate.constraintX = snapInfo.constraintX;
                                    }
                                    if (!monitorDelegate.constraintY && snapInfo.constraintY) {
                                        monitorDelegate.constraintY = snapInfo.constraintY;
                                    }

                                    const justSnappedX = monitorDelegate.constraintX && !prevConstraintX;
                                    const justSnappedY = monitorDelegate.constraintY && !prevConstraintY;
                                    const wasJustSnapped = justSnappedX || justSnappedY;

                                    const finalPos = DragLogic.calculateConstrainedPosition(
                                        parent, mouseDrivenPos,
                                        monitorDelegate.constraintX,
                                        monitorDelegate.constraintY,
                                        wasJustSnapped,
                                        monitorRepeater
                                    );

                                    if (!checkCollisionJS(parent, finalPos.x, finalPos.y)) {
                                        parent.x = finalPos.x;
                                        parent.y = finalPos.y;
                                    }

                                    updateSnapLines();
                                }

                                function updateSnapLines() {
                                    verticalSnapLine.visible = !!monitorDelegate.constraintX;
                                    horizontalSnapLine.visible = !!monitorDelegate.constraintY;

                                    if (verticalSnapLine.visible) {
                                        const target = DragLogic.findDelegateById(monitorRepeater, monitorDelegate.constraintX.id);
                                        if (target) {
                                            const edge = monitorDelegate.constraintX.edge;
                                            if (edge === "left-right") {
                                                verticalSnapLine.x = target.x + target.visualWidth;
                                            } else if (edge === "right-left") {
                                                verticalSnapLine.x = target.x;
                                            } else if (edge === "center-center") {
                                                verticalSnapLine.x = target.x + target.visualWidth / 2;
                                            }
                                        }
                                    }
                                    
                                    if (horizontalSnapLine.visible) {
                                        const target = DragLogic.findDelegateById(monitorRepeater, monitorDelegate.constraintY.id);
                                        if (target) {
                                            const edge = monitorDelegate.constraintY.edge;
                                            if (edge === "top-bottom") {
                                                horizontalSnapLine.y = target.y + target.visualHeight;
                                            } else if (edge === "bottom-top") {
                                                horizontalSnapLine.y = target.y;
                                            } else if (edge === "center-center") {
                                                horizontalSnapLine.y = target.y + target.visualHeight / 2;
                                            }
                                        }
                                    }
                                }

                                onReleased: {
                                    isDragging = false;
                                    horizontalSnapLine.visible = false;
                                    verticalSnapLine.visible = false;
                                    
                                    // Финальная привязка при отпускании
                                    const finalSnap = DragLogic.findBestSnap(parent, monitorRepeater, snapThreshold, canvas);
                                    let finalPos = Qt.point(parent.x, parent.y);

                                    if (monitorDelegate.constraintX) {
                                        finalPos.x = monitorDelegate.constraintX.snapPos;
                                    }
                                    if (monitorDelegate.constraintY) {
                                        finalPos.y = monitorDelegate.constraintY.snapPos;
                                    }
                                    
                                    // Применяем финальную позицию, если нет коллизий
                                    if (!checkCollisionJS(parent, finalPos.x, finalPos.y)) {
                                        parent.x = finalPos.x;
                                        parent.y = finalPos.y;
                                    }
                                    
                                    // Обновляем данные монитора
                                    const idx = findMonitorIndex(parent.monitorId);
                                    if (idx !== -1) {
                                       currentMonitors[idx].x = Math.round((parent.x - canvasCenter.x) / visualScale);
                                       currentMonitors[idx].y = Math.round((parent.y - canvasCenter.y) / visualScale);
                                       Qt.callLater(() => forceMonitorsUpdate());
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 350;
                Layout.fillHeight: true
                color: Theme.surfaceContainer
                visible: hasSelection

                Flickable {
                    anchors.fill: parent;
                    contentHeight: settingsColumn.implicitHeight; clip: true

                    ColumnLayout {
                        id: settingsColumn
                        width: parent.width;
                        anchors.margins: 16; spacing: 12
                        visible: root.hasSelection

                        Label { text: root.currentMonitor ? root.currentMonitor.name : qsTr("No monitor selected"); font.pixelSize: 20; font.weight: Font.Bold; color: Theme.text }
                        CheckBox {
                            text: qsTr("Enabled");
                            checked: root.currentMonitor ? !root.currentMonitor.disabled : false
                            onClicked: {
                                if (root.currentMonitor) {
                                    var mon = currentMonitors[root.currentMonitorIndex];
                                    mon.disabled = !mon.disabled;
                                    forceMonitorsUpdate();
                                }
                            }
                        }

                        Label { text: qsTr("Resolution");
                            color: Theme.subtext; topPadding: 8 }
                        StyledComboBox {
                            id: resolutionCombo;
                            Layout.fillWidth: true
                            model: resolutionsModel;
                            textRole: "text"
                            enabled: root.currentMonitor
                            onCurrentIndexChanged: {
                                if (!root.currentMonitor || currentIndex < 0 || _internalUpdate) return;
                                updateRefreshRateModel();

                                var selectedResolution = resolutionsModel.get(currentIndex).text;
                                var resParts = selectedResolution.split('x');
                                var mon = currentMonitors[root.currentMonitorIndex];
                                mon.width = parseInt(resParts[0]);
                                mon.height = parseInt(resParts[1]);
                                if (refreshRatesModel.count > 0 && refreshRateCombo.currentIndex > -1) {
                                   mon.refreshRate = parseFloat(refreshRatesModel.get(refreshRateCombo.currentIndex).text);
                                }

                                forceMonitorsUpdate();
                            }
                        }

                        Label { text: qsTr("Refresh Rate");
                            color: Theme.subtext; topPadding: 8 }
                        StyledComboBox {
                            id: refreshRateCombo;
                            Layout.fillWidth: true
                            model: refreshRatesModel;
                            textRole: "text"
                            enabled: root.currentMonitor
                            onCurrentIndexChanged: {
                                if (!root.currentMonitor || currentIndex < 0 || _internalUpdate) return;
                                var newRate = parseFloat(refreshRatesModel.get(currentIndex).text);
                                if (currentMonitors[root.currentMonitorIndex].refreshRate !== newRate) {
                                    currentMonitors[root.currentMonitorIndex].refreshRate = newRate;
                                    forceMonitorsUpdate();
                                }
                            }
                        }

                        Label { text: qsTr("Scale");
                            color: Theme.subtext; topPadding: 8 }
                        StyledTextField {
                            Layout.fillWidth: true;
                            text: root.currentMonitor ? root.currentMonitor.scale.toFixed(2) : "1.0"
                            enabled: root.currentMonitor
                            validator: DoubleValidator { bottom: 0.1;
                                top: 4.0; decimals: 2; notation: DoubleValidator.StandardNotation }
                            onEditingFinished: {
                                if(root.currentMonitor) {
                                
                                    var newScale = parseFloat(text) || 1.0;
                                    if (currentMonitors[root.currentMonitorIndex].scale !== newScale) {
                                        currentMonitors[root.currentMonitorIndex].scale = newScale;
                                        forceMonitorsUpdate();
                                    }
                                }
                            }
                        }

                         Label { text: qsTr("Position");
                            color: Theme.subtext;
                            topPadding: 8 }
                        RowLayout {
                             StyledTextField {
                                id: xPosField
                                Layout.fillWidth: true;
                                placeholderText: "X";
                                text: root.currentMonitor ? String(Math.round(root.currentMonitor.x)) : "0"
                                validator: IntValidator {}
                                enabled: root.currentMonitor
                          
                                onEditingFinished: {
                                    if(!root.currentMonitor) return;
                                    var originalX = root.currentMonitor.x;
                                    var newX = parseInt(text) || 0;
                                    if (DragLogic.checkCollision(monitorDelegate, newX, root.currentMonitor.y, monitorRepeater, currentMonitors)) {
                                        xPosField.text = String(Math.round(originalX));
                                        shakeAnimation.start();
                                    } else if (originalX !== newX) {
                                        currentMonitors[root.currentMonitorIndex].x = newX;
                                        forceMonitorsUpdate();
                                    }
                                }
                                SequentialAnimation on x {
                                    id: shakeAnimation
                                    running: false
                                    loops: 2
                                    NumberAnimation { to: xPosField.x - 3; duration: 50 }
                                    NumberAnimation { to: xPosField.x + 3; duration: 50 }
                                    NumberAnimation { to: xPosField.x; duration: 50 }
                                }
                            }
                            StyledTextField {
                                id: yPosField
                                Layout.fillWidth: true;
                                placeholderText: "Y";
                                text: root.currentMonitor ? String(Math.round(root.currentMonitor.y)) : "0"
                                validator: IntValidator {}
                                enabled: root.currentMonitor
                          
                                onEditingFinished: {
                                    if(!root.currentMonitor) return;
                                    var originalY = root.currentMonitor.y;
                                    var newY = parseInt(text) || 0;
                                    if (DragLogic.checkCollision(monitorDelegate, root.currentMonitor.x, newY, monitorRepeater, currentMonitors)) {
                                        yPosField.text = String(Math.round(originalY));
                                        shakeAnimationY.start();
                                    } else if (originalY !== newY) {
                                        currentMonitors[root.currentMonitorIndex].y = newY;
                                        forceMonitorsUpdate();
                                    }
                                }
                                SequentialAnimation on x {
                                    id: shakeAnimationY
                                    running: false
                                    loops: 2
                                    NumberAnimation { to: yPosField.x - 3; duration: 50 }
                                    NumberAnimation { to: yPosField.x + 3; duration: 50 }
                                    NumberAnimation { to: yPosField.x; duration: 50 }
                                }
                            }
                        }

                         Label { text: qsTr("Rotation");
                            color: Theme.subtext;
                            topPadding: 8 }
                        RowLayout {
                             Layout.fillWidth: true;
                             spacing: 4
                            Repeater {
                                model: ["0°", "90°", "180°", "270°"]
                                delegate: StyledButton {
                                    Layout.fillWidth: true;
                                    text: modelData; property int transformValue: index
                                    enabled: root.currentMonitor
                                    highlighted: root.currentMonitor ? root.currentMonitor.transform === transformValue : false
                                    onClicked: {
                                        if(root.currentMonitor) {
                                            currentMonitors[root.currentMonitorIndex].transform = transformValue;
                                            forceMonitorsUpdate();
                                        }
                                    }
                                }
                            }
                         }
                        RowLayout {
                             Layout.fillWidth: true;
                             spacing: 4
                            Repeater {
                                model: [qsTr("Flipped"), qsTr("Flipped 90°"), qsTr("Flipped 180°"), qsTr("Flipped 270°")]
                                delegate: StyledButton {
                                    Layout.fillWidth: true;
                                    text: modelData; property int transformValue: index + 4
                                    enabled: root.currentMonitor
                                    highlighted: root.currentMonitor ? root.currentMonitor.transform === transformValue : false
                                    onClicked: {
                                        if(root.currentMonitor) {
                                            currentMonitors[root.currentMonitorIndex].transform = transformValue;
                                            forceMonitorsUpdate();
                                        }
                                    }
                                }
                            }
                         }

                        Label { text: qsTr("Mirroring");
                            color: Theme.subtext; topPadding: 8 }
                        StyledComboBox {
                            id: mirrorCombo
                            Layout.fillWidth: true
                            model: mirrorMonitorsModel
                            textRole: "text"
                            enabled: root.currentMonitor
                          
                            onCurrentIndexChanged: {
                                if (!root.currentMonitor || currentIndex < 0 || _internalUpdate) return;
                                var sourceName = mirrorMonitorsModel.get(currentIndex).name
                                if (currentMonitors[root.currentMonitorIndex].mirrorSource !== sourceName) {
                                    currentMonitors[root.currentMonitorIndex].mirrorSource = sourceName;
                                    forceMonitorsUpdate();
                                }
                            }
                        }
                        
                         Label { text: qsTr("Advanced Display");
                            color: Theme.subtext; topPadding: 8 }
                        StyledComboBox {
                            id: vrrCombo
                            Layout.fillWidth: true
                             model: [qsTr("VRR Off"), qsTr("VRR On"), qsTr("VRR Adaptive")]
                            enabled: root.currentMonitor
                            currentIndex: root.currentMonitor ? root.currentMonitor.vrr : 0
                            onCurrentIndexChanged: {
                                if (!root.currentMonitor || _internalUpdate) return;
                                if (currentMonitors[root.currentMonitorIndex].vrr !== currentIndex) {
                                    currentMonitors[root.currentMonitorIndex].vrr = currentIndex;
                                    forceMonitorsUpdate();
                                }
                            }
                        }
                        StyledComboBox {
                             id: bitdepthCombo
                            Layout.fillWidth: true
                            topPadding: 4
                            model: ["8-bit", "10-bit"]
                             enabled: root.currentMonitor
                            currentIndex: root.currentMonitor ? (root.currentMonitor.bitdepth === 10 ? 1 : 0) : 0
                            onCurrentIndexChanged: {
                                if (!root.currentMonitor || _internalUpdate) return;
                                var newDepth = (currentIndex === 1) ? 10 : 8;
                                if (currentMonitors[root.currentMonitorIndex].bitdepth !== newDepth) {
                                    currentMonitors[root.currentMonitorIndex].bitdepth = newDepth;
                                    forceMonitorsUpdate();
                                }
                            }
                        }
                        StyledComboBox {
                             id: cmCombo
                            Layout.fillWidth: true
                            topPadding: 4
                            model: [
                                { text: "Auto", value: "auto" },
                                { text: "sRGB", value: "srgb" },
                                { text: "Wide Gamut", value: "wide" },
                                { text: "EDID", value: "edid" },
                                { text: "HDR", value: "hdr" },
                                { text: "HDR (EDID)", value: "hdredid" }
                            ]
                            textRole: "text"
                             enabled: root.currentMonitor
                            
                            Connections {
                                target: root
                                function onCurrentMonitorChanged() {
                                    if (root.currentMonitor) {
                                        var found = false;
                                        for (var i = 0; i < cmCombo.model.length; ++i) {
                                            if (cmCombo.model[i].value === root.currentMonitor.colorManagement) {
                                                _internalUpdate = true;
                                                cmCombo.currentIndex = i;
                                                _internalUpdate = false;
                                                found = true;
                                                break;
                                            }
                                        }
                                        if (!found) {
                                            _internalUpdate = true;
                                            cmCombo.currentIndex = 0; // Default to "Auto"
                                             _internalUpdate = false;
                                        }
                                    }
                                }
                            }

                             onCurrentIndexChanged: {
                                if (!root.currentMonitor || currentIndex < 0 || _internalUpdate) return;
                                var newValue = model[currentIndex].value;
                                if (currentMonitors[root.currentMonitorIndex].colorManagement !== newValue) {
                                    currentMonitors[root.currentMonitorIndex].colorManagement = newValue;
                                    forceMonitorsUpdate();
                                }
                            }
                        }
                        RowLayout {
                             visible: root.currentMonitor && (root.currentMonitor.colorManagement === 'hdr' || root.currentMonitor.colorManagement === 'hdredid')
                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("SDR Brightness")
                                text: root.currentMonitor ? root.currentMonitor.sdrBrightness.toFixed(2) : "1.0"
                                validator: DoubleValidator { bottom: 0.1; top: 4.0; decimals: 2 }
                                onEditingFinished: {
                                    if(root.currentMonitor) {
                                        currentMonitors[root.currentMonitorIndex].sdrBrightness = parseFloat(text);
                                        forceMonitorsUpdate();
                                    }
                                }
                            }
                            StyledTextField {
                                Layout.fillWidth: true
                                placeholderText: qsTr("SDR Saturation")
                                text: root.currentMonitor ? root.currentMonitor.sdrSaturation.toFixed(2) : "1.0"
                                validator: DoubleValidator { bottom: 0.1; top: 4.0; decimals: 2 }
                                onEditingFinished: {
                                    if(root.currentMonitor) {
                                        currentMonitors[root.currentMonitorIndex].sdrSaturation = parseFloat(text);
                                        forceMonitorsUpdate();
                                    }
                                }
                            }
                        }
                     }
                }
            }
        }
    }
}