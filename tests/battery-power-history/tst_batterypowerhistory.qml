import QtQuick
import QtTest

TestCase {
    id: testCase
    name: "BatteryPowerHistory"
    when: windowShown

    property url serviceUrl: Qt.resolvedUrl("../../dots/.config/quickshell/ii/services/BatteryPowerHistory.qml")

    function makeService(extra) {
        var props = { sampleInterval: 1000000 }
        if (extra) Object.keys(extra).forEach(function(k) { props[k] = extra[k] })
        var component = Qt.createComponent(serviceUrl)
        if (component.status !== Component.Ready) fail(component.errorString())
        return component.createObject(testCase, props)
    }

    function test_inactiveDoesNotCollectAndActivationSamplesValidReading() {
        const service = makeService({ powerWatts: 12.5 })
        verify(service !== null)
        compare(service.active, false)
        service.sample()
        service.powerWatts = 7.5
        compare(service.sampleCount, 0)

        service.active = true
        compare(service.sampleCount, 1)
        compare(service.samples[0], 7.5)
        service.destroy()
    }

    function test_nanZeroAndNegativeReadingsAreIgnored() {
        const service = makeService()
        verify(service !== null)
        service.active = true
        compare(service.sampleCount, 0)

        service.powerWatts = 0
        compare(service.validReading, false)
        service.sample()
        service.powerWatts = -3.2
        compare(service.validReading, false)
        service.sample()
        service.powerWatts = NaN
        compare(service.validReading, false)
        service.sample()
        compare(service.sampleCount, 0)
        service.destroy()
    }

    function test_averageUsesCollectedReadings() {
        const service = makeService({ active: true, powerWatts: 10 })
        verify(service !== null)
        service.sample()
        service.powerWatts = 20
        service.sample()
        service.powerWatts = 30
        service.sample()
        compare(service.sampleCount, 3)
        compare(service.averageWatts, 20)
        service.destroy()
    }

    function test_defaultThirtySampleLimitKeepsMostRecentValues() {
        const service = makeService({ active: true, powerWatts: 1 })
        verify(service !== null)
        compare(service.maxSamples, 30)
        for (let value = 1; value <= 35; value++) {
            service.powerWatts = value
            service.sample()
        }
        compare(service.sampleCount, 30)
        compare(service.samples[0], 6)
        compare(service.samples[29], 35)
        service.destroy()
    }

    function test_customMaxSamplesKeepsOnlyRecentValues() {
        const service = makeService({ active: true, powerWatts: 1, maxSamples: 3 })
        verify(service !== null)
        for (let value = 1; value <= 5; value++) {
            service.powerWatts = value
            service.sample()
        }
        compare(service.sampleCount, 3)
        compare(service.samples[0], 3)
        compare(service.samples[1], 4)
        compare(service.samples[2], 5)
        service.destroy()
    }

    function test_pauseResetsHistoryAndResumeStartsFresh() {
        const service = makeService({ active: true, powerWatts: 8 })
        verify(service !== null)
        service.sample()
        service.powerWatts = 10
        service.sample()
        compare(service.sampleCount, 2)

        service.active = false
        compare(service.sampleCount, 0)
        service.powerWatts = 15
        compare(service.sampleCount, 0)
        service.active = true
        compare(service.sampleCount, 1)
        compare(service.samples[0], 15)
        service.destroy()
    }

    function test_timerRunsOnlyWhileActiveAndUsesOneSecondMinimum() {
        const service = makeService({ sampleInterval: 5 })
        verify(service !== null)
        const timer = findChild(service, "batteryPowerSampleTimer")
        verify(timer !== null)
        compare(timer.interval, 1000)
        compare(timer.running, false)
        service.active = true
        compare(timer.running, true)
        service.active = false
        compare(timer.running, false)
        service.destroy()
    }

    function test_resetClearsHistoryForComparison() {
        const service = makeService({ active: true, powerWatts: 4 })
        verify(service !== null)
        service.sample()
        service.powerWatts = 6
        service.sample()
        compare(service.sampleCount, 2)
        compare(service.averageWatts, 5)

        service.reset()
        compare(service.sampleCount, 0)
        verify(isNaN(service.averageWatts))
        service.powerWatts = 9
        compare(service.sampleCount, 1)
        compare(service.averageWatts, 9)
        service.destroy()
    }
}
