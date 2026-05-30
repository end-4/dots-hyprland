from openrgb import OpenRGBClient
from openrgb.utils import RGBColor
from scipy.interpolate import interp1d
import os
from time import sleep
import argparse
from subprocess import Popen
import psutil

parser = argparse.ArgumentParser(description="Apply color on OpenRGB devices with a smooth transition")
parser.add_argument(
    "--duration",
    "-d",
    type=float,
    default=0.5,
    help="Duraton of color swap animation",
)
parser.add_argument(
    "--interpolation-steps",
    "-i",
    type=int,
    default=100,
    help="Number of steps to swap the colors (lower=choppyer, higher=smoother)",
)
parser.add_argument(
    "--color",
    "-c",
    type=str,
    help="HEX color to transition to",

)
args = parser.parse_args()

def hexToRGB(hexColor) -> list[int]:
    hexColor = hexColor.removeprefix("#")
    hexColor = [hexColor[i : i + 2] for i in range(0, 6, 2)]  # Split hex values
    intColor = [int(hexValue, 16) for hexValue in hexColor]  # Convert to int
    return intColor


def is_openrgb_running() -> bool:
    return any(p.name() == "openrgb" for p in psutil.process_iter())


def get_client(name: str = "quickshell") -> OpenRGBClient:
    for attempt in range(MAX_SEVER_START_ATTEMPTS):
        try:
            return OpenRGBClient(name=name)
        except ConnectionRefusedError:
            if not is_openrgb_running():
                Popen(["openrgb", "--server", "--startminimized"])
            sleep(SERVER_START_RETRY_DELAY)
    raise RuntimeError(f"Could not connect to OpenRGB after {MAX_SEVER_START_ATTEMPTS} attempts")


TRANSITION_DURATION = args.duration
INTERPOLATION_STEPS = args.interpolation_steps

MAX_SEVER_START_ATTEMPTS = 10
SERVER_START_RETRY_DELAY = 0.5

xdg_state_home = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
state_dir = os.path.join(xdg_state_home, "quickshell")

client = get_client()


old_color = [
    client.devices[0].leds[0].colors[0].red,
    client.devices[0].leds[0].colors[0].green,
    client.devices[0].leds[0].colors[0].blue,
]  # A bit naive but should do the trick

with open(state_dir + "/user/generated/color.txt", "r") as f:
    new_color = hexToRGB(f.read())


if args.color != None:
    new_color = hexToRGB(args.color)


for dev in client.devices:

    # set all device modes to 'Direct' (0)
    if dev.active_mode != 0:
        dev.set_mode(mode=0, save=True)


y_known = [old_color, new_color]

f = interp1d([0, 1], y_known, axis=0)


for i in range(INTERPOLATION_STEPS):
    t = i / (INTERPOLATION_STEPS - 1)
    interp_color = [int(i) for i in f(t)]
    client.set_color(RGBColor(*interp_color), True)
    sleep(TRANSITION_DURATION/INTERPOLATION_STEPS)
