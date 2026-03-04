pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.common

Singleton {
    id: root

    property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS

    onFetchIntervalChanged: {
        refreshTimer.restart();
    }

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0,
        city: "City"
    })

    property var data: ({
        uv: 0,
        humidity: 0,
        sunrise: "0:00",
        sunset: "0:00",
        windDir: "N",
        wCode: "113",
        city: "City",
        wind: "0 km/h",
        precip: "0 mm",
        visib: "0 km",
        press: "0 hPa",
        temp: "0°C",
        tempFeelsLike: "0°C",
        lastRefresh: "Never",
    })

    function wmoToWwo(wmoCode) {
        const mapping = {
            0: "113", // Clear
            1: "116", // Partly Cloudy
            2: "119", // Cloudy
            3: "122", // Overcast
            45: "143", // Fog
            48: "248", // Fog
            51: "266", // Drizzle
            53: "266",
            55: "266",
            56: "281", // Freezing Drizzle
            57: "284",
            61: "296", // Rain
            63: "302",
            65: "308",
            66: "311", // Freezing Rain
            67: "314",
            71: "326", // Snow
            73: "332",
            75: "338",
            77: "335", // Snow Grains
            80: "353", // Showers
            81: "356",
            82: "359",
            85: "368", // Snow Showers
            86: "371",
            95: "386", // Thunderstorm
            96: "389",
            99: "392"
        };
        return mapping[wmoCode] || "113";
    }

    function refineData(weatherJson) {
        if (!weatherJson || !weatherJson.current) return;

        let temp = {};
        const current = weatherJson.current;
        const daily = weatherJson.daily;

        temp.uv = current.uv_index || 0;
        temp.humidity = (current.relative_humidity_2m || 0) + "%";
        
        // Extract time from ISO8601 string (e.g., "2024-05-23T05:56")
        const formatTime = (isoStr) => isoStr ? isoStr.split("T")[1] : "0:00";
        temp.sunrise = formatTime(daily.sunrise[0]);
        temp.sunset = formatTime(daily.sunset[0]);
        
        // Wind direction simplified
        const degToDir = (deg) => {
            const dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
            return dirs[Math.round(deg / 45) % 8];
        };
        temp.windDir = degToDir(current.wind_direction_10m || 0);
        
        temp.wCode = root.wmoToWwo(current.weather_code);
        temp.city = root.location.city;

        if (root.useUSCS) {
            temp.wind = Math.round(current.wind_speed_10m * 0.621371) + " mph";
            temp.precip = current.precipitation + " in"; // Open-Meteo can be configured for inches, but we'll stick to metric internally or adjust URL
            temp.visib = Math.round(current.visibility / 1609.34) + " mi";
            temp.press = Math.round(current.pressure_msl * 0.0145038) + " psi";
            temp.temp = Math.round(current.temperature_2m * 9/5 + 32) + "°F";
            temp.tempFeelsLike = Math.round(current.apparent_temperature * 9/5 + 32) + "°F";
        } else {
            temp.wind = Math.round(current.wind_speed_10m) + " km/h";
            temp.precip = current.precipitation + " mm";
            temp.visib = Math.round(current.visibility / 1000) + " km";
            temp.press = Math.round(current.pressure_msl) + " hPa";
            temp.temp = Math.round(current.temperature_2m) + "°C";
            temp.tempFeelsLike = Math.round(current.apparent_temperature) + "°C";
        }
        
        temp.lastRefresh = DateTime.time + " • " + DateTime.date;
        root.data = temp;
    }

    function getData() {
        locationFetcher.running = true;
    }

    Process {
        id: locationFetcher
        command: ["curl", "-s", "http://ip-api.com/json"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return;
                try {
                    const loc = JSON.parse(text);
                    if (loc.status === "success") {
                        root.location.lat = loc.lat;
                        root.location.lon = loc.lon;
                        root.location.city = loc.city;
                        root.location.valid = true;
                        
                        // Now fetch weather
                        weatherFetcher.fetch();
                    }
                } catch (e) {
                    console.error(`[WeatherService] Location Error: ${e.message}`);
                }
            }
        }
    }

    Process {
        id: weatherFetcher
        function fetch() {
            let url = `https://api.open-meteo.com/v1/forecast?latitude=${root.location.lat}&longitude=${root.location.lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,uv_index,visibility&daily=sunrise,sunset&timezone=auto&forecast_days=1`;
            command = ["curl", "-s", url];
            running = true;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return;
                try {
                    const weather = JSON.parse(text);
                    root.refineData(weather);
                } catch (e) {
                    console.error(`[WeatherService] Weather Error: ${e.message}`);
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: root.fetchInterval
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.getData()
    }

    onUseUSCSChanged: root.getData()

    Component.onCompleted: {
        console.info("[WeatherService] Initialized with ip-api and Open-Meteo.");
    }
}
