// colors.js
var subcolors = [
  { name: "os", color: "#6C5CE7" }, // deep violet
  { name: "se", color: "#00B894" }, // teal green
  { name: "iot", color: "#FABE58" }, // warm amber
  { name: "ada", color: "#E17055" }, // soft orange
  { name: "c2p", color: "#0984E3" }, // bright blue
  { name: "cap", color: "#D63031" }, // red
  { name: "ap", color: "#E84393" }, // pink
  { name: "mn", color: "#befb7a" }  // light green
]

// is string include in subcolors
function isIncludeInSubColor(str) {
  str = str.toLowerCase();
  for (let index = 0; index < subcolors.length; index++) {
    const element = subcolors[index];
    if (element.name == str) {
      return [true, element.color];
    }
  }
  return [false, null];
}

function hslToHex(h, s, l) {
  s /= 100;
  l /= 100;

  let c = (1 - Math.abs(2 * l - 1)) * s;
  let x = c * (1 - Math.abs((h / 60) % 2 - 1));
  let m = l - c / 2;
  let r = 0, g = 0, b = 0;

  if (0 <= h && h < 60) { r = c; g = x; b = 0; }
  else if (60 <= h && h < 120) { r = x; g = c; b = 0; }
  else if (120 <= h && h < 180) { r = 0; g = c; b = x; }
  else if (180 <= h && h < 240) { r = 0; g = x; b = c; }
  else if (240 <= h && h < 300) { r = x; g = 0; b = c; }
  else if (300 <= h && h < 360) { r = c; g = 0; b = x; }

  r = Math.round((r + m) * 255);
  g = Math.round((g + m) * 255);
  b = Math.round((b + m) * 255);

  return "#" + [r, g, b].map(x =>
    x.toString(16).padStart(2, "0")
  ).join("");
}

function stringToColor(str) {

  // check for include
  let islnc = isIncludeInSubColor(str);
  if (islnc[0]) {
    return islnc[1]
  }

  // Hash string to integer
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
  }

  let hue = Math.abs(hash) % 360;

  // Muted palette: lower saturation, higher lightness
  let saturation = 80; // % (less vibrant = more natural)
  let lightness = 60;  // % (so it’s not too dark or too bright)

  return hslToHex(hue, saturation, lightness);
}


var days = [
  {
    name: "Monday",
    events: [
      {
        start: "15:30",
        end: "19:00",
        title: "MI",
        color: stringToColor("MI")
      },
    ]
  },
  {
    name: "Tuesday",
    events: [
      {
        start: "7:30",
        end: "9:20",
        title: "OS (KVP) - B6",
        color: stringToColor("OS")
      },
      {
        start: "9:50",
        end: "10:45",
        title: "IOT (YBS)",
        color: stringToColor("IOT")
      },
      {
        start: "10:45",
        end: "11:40",
        title: "SE (NPB)",
        color: stringToColor("SE")
      },
      {
        start: "11:50",
        end: "12:45",
        title: "ADA (BUT)",
        color: stringToColor("ADA")
      },
      {
        start: "12:45",
        end: "13:40",
        title: "C2P (NMV)",
        color: stringToColor("C2P")
      },
      {
        start: "15:30",
        end: "19:00",
        title: "MI",
        color: stringToColor("MI")
      },
    ]
  },
  {
    name: "Wednesday",
    events: [
      {
        start: "7:30",
        end: "8:25",
        title: "OS (KVP)",
        color: stringToColor("OS")
      },
      {
        start: "8:25",
        end: "9:20",
        title: "ADA (BUT)",
        color: stringToColor("ADA")
      },
      {
        start: "9:50",
        end: "11:40",
        title: "IOT (YBS) - 131",
        color: stringToColor("IOT")
      },
      {
        start: "11:50",
        end: "13:40",
        title: "AP (DRP) - B7",
        color: stringToColor("AP")
      },
      {
        start: "15:30",
        end: "19:00",
        title: "MI",
        color: stringToColor("MI")
      },
    ]
  },
  {
    name: "Thursday",
    events: [
      {
        start: "8:25",
        end: "9:20",
        title: "OS (KVP)",
        color: stringToColor("OS")
      },
      {
        start: "9:50",
        end: "10:45",
        title: "IOT (YBS)",
        color: stringToColor("IOT")
      },
      {
        start: "10:45",
        end: "11:40",
        title: "SE (NPB)",
        color: stringToColor("SE")
      },
      {
        start: "11:50",
        end: "13:40",
        title: "ADA (BUT) - B5",
        color: stringToColor("ADA")
      },
      {
        start: "15:30",
        end: "19:00",
        title: "MI",
        color: stringToColor("MI")
      },
    ]
  },
  {
    name: "Friday",
    events: [
      {
        start: "7:30",
        end: "8:25",
        title: "AP (DRP)",
        color: stringToColor("AP")
      },
      {
        start: "8:25",
        end: "9:20",
        title: "MN (SJ)",
        color: stringToColor("MN")
      },
      {
        start: "9:50",
        end: "10:45",
        title: "C2P (NMV)",
        color: stringToColor("C2P")
      },
      {
        start: "10:45",
        end: "11:40",
        title: "IOT (YBS)",
        color: stringToColor("IOT")
      },
      {
        start: "11:50",
        end: "13:40",
        title: "CAP (NRV)",
        color: stringToColor("CAP")
      },
      {
        start: "15:30",
        end: "19:00",
        title: "MI",
        color: stringToColor("MI")
      },
    ]
  },
  {
    name: "Saturday",
    events: [
      {
        start: "7:30",
        end: "8:25",
        title: "ADA (BUT)",
        color: stringToColor("ADA")
      },
      {
        start: "8:25",
        end: "9:20",
        title: "AP (DRP)",
        color: stringToColor("AP")
      },
      {
        start: "9:50",
        end: "11:40",
        title: "SE (NPB) - 142",
        color: stringToColor("SE")
      },
      {
        start: "11:50",
        end: "12:45",
        title: "OS (KVP)",
        color: stringToColor("OS")
      },
      {
        start: "15:30",
        end: "19:00",
        title: "MI",
        color: stringToColor("MI")
      },
    ]
  },
  {
    name: "Sunday",
    events: []
  }
]
