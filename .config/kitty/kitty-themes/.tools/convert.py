import json
from jinja2 import FileSystemLoader, Environment
import sys
import os


def removeAlpha(value):
    hex = value.lstrip("#")
    return "#" + hex[0:6]


filename = sys.argv[1]

kitty_configuration = os.path.splitext(filename)[0] + ".conf"

with open(filename, "r") as configuration_file:
    configuration = json.load(configuration_file)

loader = FileSystemLoader(".")
env = Environment(loader=loader)

env.filters['removeAlpha'] = removeAlpha
env.trim_blocks = True

template = env.get_template("template.conf.j2")

output = template.render(**configuration)

with open(kitty_configuration, "w") as fp:
    fp.write(output)
