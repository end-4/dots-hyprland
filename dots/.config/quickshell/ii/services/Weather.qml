pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root
    // Polling interval in ms (config is in minutes; default 10 min)
    readonly property int fetchInterval: Math.max(60000, (Config.options?.bar?.weather?.fetchInterval ?? 10) * 60 * 1000)
    readonly property string city: Config.options.bar.weather.city
    readonly property string provider: Config.options.bar.weather.provider || "wttr"
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    property bool gpsActive: Config.options.bar.weather.enableGPS
    property string _pendingProvider: "wttr" // which provider the in-flight request is for

    onUseUSCSChanged: {
        root.getData();
    }
    onCityChanged: {
        root.getData();
    }
    onProviderChanged: {
        root.getData();
    }

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0
    })

    property var data: ({
        uv: 0,
        humidity: 0,
        sunrise: 0,
        sunset: 0,
        windDir: 0,
        wCode: 0,
        city: 0,
        wind: 0,
        precip: 0,
        visib: 0,
        press: 0,
        temp: 0,
        tempFeelsLike: 0,
        lastRefresh: 0,
    })

    function refineData(data) {
        let temp = {};
        temp.uv = data?.current?.uvIndex || 0;
        temp.humidity = (data?.current?.humidity || 0) + "%";
        temp.sunrise = data?.astronomy?.sunrise || "0.0";
        temp.sunset = data?.astronomy?.sunset || "0.0";
        temp.windDir = data?.current?.winddir16Point || "N";
        temp.wCode = data?.current?.weatherCode || "113";
        temp.city = data?.location?.areaName[0]?.value || "City";
        temp.temp = "";
        temp.tempFeelsLike = "";
        if (root.useUSCS) {
            temp.wind = (data?.current?.windspeedMiles || 0) + " mph";
            temp.precip = (data?.current?.precipInches || 0) + " in";
            temp.visib = (data?.current?.visibilityMiles || 0) + " m";
            temp.press = (data?.current?.pressureInches || 0) + " psi";
            temp.temp += (data?.current?.temp_F || 0);
            temp.tempFeelsLike += (data?.current?.FeelsLikeF || 0);
            temp.temp += "°F";
            temp.tempFeelsLike += "°F";
        } else {
            temp.wind = (data?.current?.windspeedKmph || 0) + " km/h";
            temp.precip = (data?.current?.precipMM || 0) + " mm";
            temp.visib = (data?.current?.visibility || 0) + " km";
            temp.press = (data?.current?.pressure || 0) + " hPa";
            temp.temp += (data?.current?.temp_C || 0);
            temp.tempFeelsLike += (data?.current?.FeelsLikeC || 0);
            temp.temp += "°C";
            temp.tempFeelsLike += "°C";
        }
        temp.lastRefresh = DateTime.time + " • " + DateTime.date;
        root.data = temp;
    }

    // Convert wind direction degrees to 16-point compass (wttr-style)
    function windDegTo16Point(deg) {
        if (deg == null || isNaN(deg)) return "N";
        const points = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"];
        const idx = Math.round(((deg % 360) + 360) % 360 / 22.5) % 16;
        return points[idx];
    }

    // Map Open-Meteo WMO weather codes (0-99) to wttr.in codes used by Icons.weatherIconMap
    function wmoToWttrCode(wmo) {
        if (wmo == null || wmo === undefined) return "113";
        const n = Number(wmo);
        if (n === 0) return "113";   // Clear
        if (n === 1 || n === 2) return "116"; // Mainly clear, partly cloudy
        if (n === 3) return "119";   // Overcast
        if (n === 45 || n === 48) return "143"; // Fog
        if (n >= 61 && n <= 67) return "296";  // Rain / freezing rain
        if (n >= 51 && n <= 57) return "176"; // Drizzle
        if (n >= 71 && n <= 77) return "335";  // Snow
        if (n >= 80 && n <= 82) return "176"; // Rain showers
        if (n >= 85 && n <= 86) return "335"; // Snow showers
        if (n === 95) return "200";  // Thunderstorm
        if (n >= 96 && n <= 99) return "386"; // Thunderstorm with hail
        return "119"; // default cloud
    }

    function refineDataOpenMeteo(data) {
        const cur = data?.current || {};
        const daily = data?.daily || {};
        const sunrise = (daily.sunrise && daily.sunrise[0]) ? daily.sunrise[0].slice(11, 16) : "—";
        const sunset = (daily.sunset && daily.sunset[0]) ? daily.sunset[0].slice(11, 16) : "—";
        const round = (v) => (v != null && !isNaN(v)) ? Math.round(Number(v)) : 0;
        let temp = {};
        temp.uv = 0;
        temp.humidity = round(cur.relative_humidity_2m) + "%";
        temp.sunrise = sunrise;
        temp.sunset = sunset;
        temp.windDir = root.windDegTo16Point(cur.wind_direction_10m);
        temp.wCode = root.wmoToWttrCode(cur.weather_code);
        temp.city = root.city || "City";
        temp.temp = "";
        temp.tempFeelsLike = "";
        if (root.useUSCS) {
            const mph = round(cur.wind_speed_10m);
            const psi = cur.surface_pressure != null ? (cur.surface_pressure / 68.9476).toFixed(2) : "0";
            const precipIn = cur.precipitation != null ? (cur.precipitation / 25.4).toFixed(2) : "0";
            const visMiles = cur.visibility != null ? (cur.visibility / 1.609).toFixed(1) : "0";
            temp.wind = mph + " mph";
            temp.precip = precipIn + " in";
            temp.visib = visMiles + " mi";
            temp.press = psi + " psi";
            temp.temp = round(cur.temperature_2m) + "°F";
            temp.tempFeelsLike = round(cur.apparent_temperature != null ? cur.apparent_temperature : cur.temperature_2m) + "°F";
        } else {
            temp.wind = round(cur.wind_speed_10m) + " km/h";
            temp.precip = (cur.precipitation != null ? cur.precipitation : 0) + " mm";
            temp.visib = (cur.visibility != null ? cur.visibility : 0) + " km";
            temp.press = (cur.surface_pressure != null ? cur.surface_pressure : 0) + " hPa";
            temp.temp = round(cur.temperature_2m) + "°C";
            temp.tempFeelsLike = round(cur.apparent_temperature != null ? cur.apparent_temperature : cur.temperature_2m) + "°C";
        }
        temp.lastRefresh = DateTime.time + " • " + DateTime.date;
        root.data = temp;
    }

    function getData() {
        root._pendingProvider = root.provider;

        if (root.provider === "open") {
            // Open-Meteo: geocode city then forecast, or use GPS coords
            let lat = root.location.lat, lon = root.location.long;
            let useCoords = root.gpsActive && root.location.valid;
            const uscs = root.useUSCS ? "true" : "false";
            const cityEnc = formatCityName(root.city);
            if (useCoords) {
                const url = root.useUSCS
                    ? `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure,precipitation,visibility&daily=sunrise,sunset&temperature_unit=fahrenheit&wind_speed_unit=mph`
                    : `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure,precipitation,visibility&daily=sunrise,sunset`;
                fetcher.command[2] = `curl -s --max-time 15 "${url}"`;
            } else {
                fetcher.command[2] = `GEO=$(curl -s --max-time 12 "https://geocoding-api.open-meteo.com/v1/search?name=${cityEnc}&count=1"); LAT=$(echo "$GEO" | jq -r '.results[0].latitude // empty'); LON=$(echo "$GEO" | jq -r '.results[0].longitude // empty'); if [ -n "$LAT" ] && [ -n "$LON" ]; then UNIT=""; [ "${uscs}" = "true" ] && UNIT="&temperature_unit=fahrenheit&wind_speed_unit=mph"; curl -s --max-time 12 "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure,precipitation,visibility&daily=sunrise,sunset$UNIT"; fi`;
            }
            fetcher.running = true;
            return;
        }

        // wttr.in
        let command = "curl -s --max-time 15 -A 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko)' -H 'Accept-Language: en' wttr.in";
        if (root.gpsActive && root.location.valid) {
            command += `/${root.location.lat},${root.location.long}`;
        } else {
            command += `/${formatCityName(root.city)}`;
        }
        command += "?format=j1";
        command += " | ";
        command += "jq '{current: .current_condition[0], location: .nearest_area[0], astronomy: .weather[0].astronomy[0]}'";
        fetcher.command[2] = command;
        fetcher.running = true;
    }

    function formatCityName(cityName) {
        return cityName.trim().split(/\s+/).join('+');
    }

    property bool _initialFetchDone: false

    Component.onCompleted: {
        if (root.gpsActive) {
            console.info("[WeatherService] Starting the GPS service.");
            positionSource.start();
        } else {
            root.getData();
            if (Config.ready)
                root._initialFetchDone = true;
        }
        initialFetchTimer.start();
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready && !root.gpsActive) {
                root.getData();
                root._initialFetchDone = true;
            }
        }
    }

    Timer {
        id: initialFetchTimer
        interval: 3500
        repeat: false
        running: false
        onTriggered: {
            if (!root.gpsActive) root.getData();
            root._initialFetchDone = true;
        }
    }

    Timer {
        id: openMeteoRetryTimer
        interval: 8000
        repeat: false
        running: false
        onTriggered: {
            if (root.provider === "open" && !root.gpsActive) root.getData();
        }
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) {
                    if (root._pendingProvider === "open")
                        openMeteoRetryTimer.restart();
                    return;
                }
                try {
                    const parsedData = JSON.parse(text);
                    if (root._pendingProvider === "open")
                        root.refineDataOpenMeteo(parsedData);
                    else
                        root.refineData(parsedData);
                } catch (e) {
                    console.error(`[WeatherService] ${e.message}`);
                    if (root._pendingProvider === "open")
                        openMeteoRetryTimer.restart();
                }
            }
        }
    }

    PositionSource {
        id: positionSource
        updateInterval: root.fetchInterval

        onPositionChanged: {
            // update the location if the given location is valid
            // if it fails getting the location, use the last valid location
            if (position.latitudeValid && position.longitudeValid) {
                root.location.lat = position.coordinate.latitude;
                root.location.long = position.coordinate.longitude;
                root.location.valid = true;
                // console.info(`📍 Location: ${position.coordinate.latitude}, ${position.coordinate.longitude}`);
                root.getData();
                // if can't get initialized with valid location deactivate the GPS
            } else {
                root.gpsActive = root.location.valid ? true : false;
                console.error("[WeatherService] Failed to get the GPS location.");
            }
        }

        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop();
                root.location.valid = false;
                root.gpsActive = false;
                Quickshell.execDetached(["notify-send", Translation.tr("Weather Service"), Translation.tr("Cannot find a GPS service. Using the fallback method instead."), "-a", "Shell"]);
                console.error("[WeatherService] Could not aquire a valid backend plugin.");
            }
        }
    }

    // Always run periodic refresh: with GPS, PositionSource only fires on position *change*,
    // so when stationary we'd never re-fetch. Timer ensures we poll every fetchInterval.
    Timer {
        id: refreshTimer
        running: true
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: true
        onTriggered: root.getData()
    }
}
