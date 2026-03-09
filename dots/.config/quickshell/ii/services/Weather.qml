pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.modules.common
import qs.services

Singleton {
    id: root

    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    
    // For backward compatibility and UI settings
    property bool gpsActive: Config.options.bar.weather.enableGPS
    readonly property string city: Config.options.bar.weather.city

    onUseUSCSChanged: getData()
    onCityChanged: getData()
    onGpsActiveChanged: getData()
    onFetchIntervalChanged: {
        timer.restart();
    }

    property var data: ({
        uv: 0,
        humidity: "0%",
        sunrise: "00:00",
        sunset: "00:00",
        windDir: "N",
        wCode: 113,
        city: "City",
        wind: "0 km/h",
        precip: "0 mm",
        visib: "0 km",
        press: "0 hPa",
        temp: "0°C",
        tempFeelsLike: "0°C",
        lastRefresh: "00:00",
    })

    function wmoToWwo(wmo) {
        if (wmo === 0 || wmo === 1) return 113; // Clear
        if (wmo === 2) return 116; // Partly Cloudy
        if (wmo === 3) return 122; // Overcast
        if (wmo === 45 || wmo === 48) return 248; // Fog
        if (wmo === 51 || wmo === 53 || wmo === 55) return 266; // Drizzle
        if (wmo === 56 || wmo === 57) return 284; // Freezing Drizzle
        if (wmo === 61 || wmo === 63 || wmo === 65) return 296; // Rain
        if (wmo === 66 || wmo === 67) return 311; // Freezing Rain
        if (wmo === 71 || wmo === 73 || wmo === 75 || wmo === 77) return 332; // Snow
        if (wmo === 80 || wmo === 81 || wmo === 82) return 353; // Rain Showers
        if (wmo === 85 || wmo === 86) return 368; // Snow Showers
        if (wmo === 95) return 386; // Thunderstorm
        if (wmo === 96 || wmo === 99) return 389; // Thunderstorm with hail
        return 113;
    }

    function degreesToCompass(deg) {
        const val = Math.floor((deg / 22.5) + 0.5);
        const arr = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
        return arr[(val % 16)];
    }

    function formatTime(isoStr) {
        if (!isoStr) return "00:00";
        const parts = isoStr.split("T");
        if (parts.length < 2) return isoStr;
        return parts[1];
    }

    function refineData(wData, cityName) {
        let temp = {};
        const current = wData.current;
        const daily = wData.daily;

        temp.uv = current.uv_index;
        temp.humidity = current.relative_humidity_2m + "%";
        temp.sunrise = formatTime(daily.sunrise[0]);
        temp.sunset = formatTime(daily.sunset[0]);
        temp.windDir = degreesToCompass(current.wind_direction_10m);
        temp.wCode = wmoToWwo(current.weather_code);
        temp.city = cityName;
        
        if (root.useUSCS) {
            temp.wind = Math.round(current.wind_speed_10m) + " mph";
            temp.precip = current.precipitation.toFixed(2) + " in";
            temp.visib = (current.visibility / 1609.34).toFixed(1) + " mi";
            temp.press = Math.round(current.pressure_msl) + " hPa"; 
            temp.temp = Math.round(current.temperature_2m) + "°F";
            temp.tempFeelsLike = Math.round(current.apparent_temperature) + "°F";
        } else {
            temp.wind = Math.round(current.wind_speed_10m) + " km/h";
            temp.precip = current.precipitation.toFixed(1) + " mm";
            temp.visib = (current.visibility / 1000).toFixed(1) + " km";
            temp.press = Math.round(current.pressure_msl) + " hPa";
            temp.temp = Math.round(current.temperature_2m) + "°C";
            temp.tempFeelsLike = Math.round(current.apparent_temperature) + "°C";
        }
        
        temp.lastRefresh = DateTime.time + " • " + DateTime.date;
        root.data = temp;
    }

    function getData() {
        if (root.city !== "" && !root.gpsActive) {
            // If manual city is set and GPS is off, use geocoding
            fetchCoordinates(root.city);
        } else {
            // Default to ip-api for automatic location
            const xhr = new XMLHttpRequest();
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            const loc = JSON.parse(xhr.responseText);
                            if (loc.status === "success") {
                                fetchWeather(loc.lat, loc.lon, loc.city);
                            } else {
                                console.error("[WeatherService] ip-api failed:", loc.message);
                            }
                        } catch (e) {
                            console.error("[WeatherService] Failed to parse location:", e);
                        }
                    }
                }
            };
            xhr.open("GET", "http://ip-api.com/json/");
            xhr.send();
        }
    }

    function fetchCoordinates(cityName) {
        const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(cityName)}&count=1&language=en&format=json`;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const res = JSON.parse(xhr.responseText);
                        if (res.results && res.results.length > 0) {
                            const loc = res.results[0];
                            fetchWeather(loc.latitude, loc.longitude, loc.name);
                        } else {
                            console.error("[WeatherService] Geocoding failed for:", cityName);
                        }
                    } catch (e) {
                        console.error("[WeatherService] Failed to parse geocoding:", e);
                    }
                }
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function fetchWeather(lat, lon, cityName) {
        const units = root.useUSCS ? "&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch" : "";
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,pressure_msl,wind_speed_10m,wind_direction_10m,uv_index,visibility&daily=sunrise,sunset&timezone=auto${units}`;
        
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const weather = JSON.parse(xhr.responseText);
                        root.refineData(weather, cityName);
                    } catch (e) {
                        console.error("[WeatherService] Failed to parse weather:", e);
                    }
                }
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    Timer {
        id: timer
        running: Config.options.bar.weather.enable
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: true
        onTriggered: root.getData()
    }
}
