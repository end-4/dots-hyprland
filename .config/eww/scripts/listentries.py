#!/usr/bin/python3

import desktop_entry_lib
import os
import json
import subprocess

full_output = {}

def read(target_file) -> None:
    entry = desktop_entry_lib.DesktopEntry.from_file(target_file)

    print("Name: " + str(entry.Name.default_text))
    print("Comment: " + str(entry.Comment.default_text))
    print("Exec: " + str(entry.Exec))


def getProperties(target_file) -> None:
    entry = desktop_entry_lib.DesktopEntry.from_file(target_file)

    # iconcmd = "/usr/bin/geticons " + str(entry.Icon)
    # iconcmd = "/usr/bin/geticons"
    # iconpath = str(subprocess.check_output(str(iconcmd), shell=True))
    dirs = target_file.split('/')
    entryname = dirs[-1]

    # return
    props = {
        "name": str(entry.Name.default_text),
        # "icon": str(entry.Icon),
        "exec": str('gtk-launch ' + entryname)
    }
    return props


if __name__ == "__main__":
    entryFile = open("scripts/cache/entries.txt", "w")
    # Get files
    entries = list(str(s) for s in os.listdir("/usr/share/applications"))
    entries_flatpak = list(str(s) for s in os.listdir("/var/lib/flatpak/exports/share/applications"))
    entries_local = list(str('../../.local/share/applications/' + s) for s in os.listdir("../../.local/share/applications/"))
    
    for app in entries:
        alreadythere = False
        for localized in entries_local:
            if app in localized:
                alreadythere = True

        if not(alreadythere):
            entries_local.append(str('/usr/share/applications/'+app))

    for app in entries_flatpak:
        alreadythere = False
        for localized in entries_local:
            if app in localized:
                alreadythere = True

        if not(alreadythere):
            entries_local.append(str('/var/lib/flatpak/exports/share/applications/'+app))

    # Get properties
    for app in entries_local:
        if app.find('.desktop') == -1: # Skip files that aren't desktop entries
            continue
        this_entry = getProperties(app)

        full_output[this_entry['name']] = (this_entry)

        # output=json.dumps(this_entry)
        # print(output)
    entryFile.write(json.dumps(full_output))