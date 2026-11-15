import QtQuick
import QtTest

TestCase {
    id: testCase
    name: "WallpaperRotation"
    when: windowShown

    property url serviceUrl: Qt.resolvedUrl("../../dots/.config/quickshell/ii/services/WallpaperRotation.qml")
    property url mixedFolder: Qt.resolvedUrl("fixtures/mixed")
    property url emptyFolder: Qt.resolvedUrl("fixtures/empty")
    property url singleFolder: Qt.resolvedUrl("fixtures/single")

    function makeService(folder, extra) {
        var props = { folder: folder, currentWallpaper: Qt.resolvedUrl("fixtures/not-current.png"), extensions: ["png", "jpg"], randomOnStartup: false }
        if (extra) Object.keys(extra).forEach(function(k) { props[k] = extra[k] })
        var component = Qt.createComponent(testCase.serviceUrl)
        if (component.status !== Component.Ready) fail(component.errorString())
        return component.createObject(testCase, props)
    }

    function test_absoluteCurrentWallpaperPath() {
        const current = Qt.resolvedUrl("fixtures/mixed/a.png").toString().replace(/^file:\/\//, "");
        const service = makeService(mixedFolder, { currentWallpaper: current });
        verify(service !== null);
        tryCompare(service, "count", 2);
        let selected = "";
        service.wallpaperSelected.connect(path => selected = path);
        service.rotate();
        verify(selected.endsWith("b.jpg"));
        service.destroy();
    }

    function test_absoluteFilesystemPath() {
        const path = mixedFolder.toString().replace(/^file:\/\//, "");
        const service = makeService(path);
        verify(service !== null);
        tryCompare(service, "count", 2);
        service.destroy();
    }

    function test_filtersFilesAndExcludesSubfolders() {
        var service = makeService(mixedFolder)
        verify(service !== null)
        tryCompare(service, "count", 2)
        var selected = ""
        service.wallpaperSelected.connect(function(path) { selected = path })
        service.rotate()
        verify(selected.endsWith("a.png") || selected.endsWith("b.jpg"))
        verify(!selected.includes("nested.png"))
        service.destroy()
    }

    function test_excludesCurrentWallpaper() {
        var service = makeService(mixedFolder, { currentWallpaper: Qt.resolvedUrl("fixtures/mixed/a.png") })
        verify(service !== null)
        tryCompare(service, "count", 2)
        var selected = ""
        service.wallpaperSelected.connect(function(path) { selected = path })
        service.rotate()
        verify(selected.endsWith("b.jpg"))
        service.destroy()
    }

    function test_singleCurrentWallpaperIsNoOp() {
        var service = makeService(singleFolder, { currentWallpaper: Qt.resolvedUrl("fixtures/single/only.png") })
        verify(service !== null)
        tryCompare(service, "count", 1)
        var selections = 0
        service.wallpaperSelected.connect(function() { selections++ })
        service.rotate()
        compare(selections, 0)
        service.destroy()
    }

    function test_emptyAndMissingFoldersDoNotSelect() {
        var empty = makeService(emptyFolder)
        verify(empty !== null)
        tryCompare(empty, "count", 0)
        var emptySelections = 0
        empty.wallpaperSelected.connect(function() { emptySelections++ })
        empty.rotate()
        compare(emptySelections, 0)
        empty.destroy()

        var missing = makeService(Qt.resolvedUrl("fixtures/no-such-folder"))
        verify(missing !== null)
        tryCompare(missing, "count", 0)
        var missingSelections = 0
        missing.wallpaperSelected.connect(function() { missingSelections++ })
        missing.rotate()
        compare(missingSelections, 0)
        missing.destroy()
    }

    function test_busyPreventsSelection() {
        var service = makeService(mixedFolder, { busy: true })
        verify(service !== null)
        tryCompare(service, "count", 2)
        var selections = 0
        service.wallpaperSelected.connect(function() { selections++ })
        service.rotate()
        compare(selections, 0)
        service.destroy()
    }

    function test_startupRotationIsOptional() {
        var disabled = makeService(mixedFolder, { randomOnStartup: false })
        verify(disabled !== null)
        tryCompare(disabled, "count", 2)
        var disabledSelections = 0
        disabled.wallpaperSelected.connect(function() { disabledSelections++ })
        wait(50)
        compare(disabled.startupPending, false)
        compare(disabledSelections, 0)
        disabled.destroy()

        var enabled = makeService(mixedFolder, { randomOnStartup: true })
        verify(enabled !== null)
        var enabledSelections = 0
        enabled.wallpaperSelected.connect(function() { enabledSelections++ })
        tryCompare(enabled, "count", 2)
        tryCompare(enabled, "startupPending", false)
        tryVerify(function() { return enabledSelections === 1 }, 250)
        enabled.destroy()
    }

    function test_pausedStopsTimerUntilResumed() {
        var service = makeService(mixedFolder, { paused: true, intervalMinutes: 1 })
        verify(service !== null)
        tryCompare(service, "count", 2)
        var timer = findChild(service, "rotationTimer")
        verify(timer !== null)
        compare(timer.running, false)
        timer.interval = 20
        var selections = 0
        service.wallpaperSelected.connect(function() { selections++ })
        wait(80)
        compare(selections, 0)
        service.paused = false
        tryCompare(timer, "running", true)
        tryVerify(function() { return selections >= 2 }, 250)
        service.destroy()
    }

    function test_manualRotateRemainsAvailableWhilePaused() {
        var service = makeService(mixedFolder, { paused: true })
        verify(service !== null)
        tryCompare(service, "count", 2)
        var selections = 0
        service.wallpaperSelected.connect(function() { selections++ })
        service.rotate()
        compare(selections, 1)
        service.destroy()
    }

    function test_pausedStartupRemainsPendingUntilResumed() {
        var service = makeService(mixedFolder, { paused: true, randomOnStartup: true })
        verify(service !== null)
        var selections = 0
        service.wallpaperSelected.connect(function() { selections++ })
        tryCompare(service, "count", 2)
        wait(60)
        compare(service.startupPending, true)
        compare(selections, 0)
        service.paused = false
        tryCompare(service, "startupPending", false)
        tryVerify(function() { return selections === 1 }, 250)
        service.destroy()
    }

    function test_intervalIsClampedToOneMinuteAndOneDay() {
        var service = makeService(mixedFolder, { intervalMinutes: 0.1 })
        verify(service !== null)
        var timer = findChild(service, "rotationTimer")
        verify(timer !== null)
        compare(timer.interval, 60000)
        service.intervalMinutes = 2000
        compare(timer.interval, 86400000)
        service.destroy()
    }

    function test_loaderUnloadDestroysAndReloadsService() {
        var loader = Qt.createQmlObject('import QtQuick; Loader { active: false }', testCase, "testLoader")
        verify(loader !== null)
        loader.setSource(serviceUrl, { folder: mixedFolder, currentWallpaper: Qt.resolvedUrl("fixtures/not-current.png"), extensions: ["png", "jpg"], randomOnStartup: false })
        loader.active = true
        tryVerify(function() { return loader.item !== null }, 1000)
        var firstItem = loader.item
        tryCompare(firstItem, "count", 2)
        loader.active = false
        tryCompare(loader, "item", null)
        loader.active = true
        tryVerify(function() { return loader.item !== null }, 1000)
        verify(loader.item !== firstItem)
        loader.destroy()
    }

    function test_repeatingTimerAndChangedInterval() {
        var service = makeService(mixedFolder, { intervalMinutes: 10 })
        verify(service !== null)
        tryCompare(service, "count", 2)
        compare(service.intervalMinutes, 10)
        var timer = findChild(service, "rotationTimer")
        verify(timer !== null)
        compare(timer.repeat, true)
        compare(timer.interval, 600000)
        service.intervalMinutes = 20
        compare(timer.interval, 1200000)
        timer.interval = 20
        var selections = 0
        service.wallpaperSelected.connect(function() { selections++ })
        tryVerify(function() { return selections >= 2 }, 250)
        service.busy = true
        tryCompare(timer, "running", false)
        var stoppedAt = selections
        wait(60)
        compare(selections, stoppedAt)
        service.busy = false
        tryCompare(timer, "running", true)
        tryVerify(function() { return selections >= stoppedAt + 2 }, 250)
        service.destroy()
    }
}
