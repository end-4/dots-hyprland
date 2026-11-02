#!/usr/bin/env python3
"""Anade a un JSON de traducciones de ii las claves del dashboard que aun no tenga.

Uso: merge_translations.py <ii/translations/es_MX.json> <translations/dashboard.es.json>
Nunca sobrescribe una clave existente. Conserva la indentacion del archivo destino.
"""
import json
import re
import sys

target, fragment = sys.argv[1], sys.argv[2]
raw = open(target, encoding="utf-8").read()
m = re.search(r"\n([ \t]+)\"", raw)
indent = m.group(1) if m else "  "
data = json.loads(raw)
new = json.load(open(fragment, encoding="utf-8"))
added = [k for k in new if k not in data]
for k in added:
    data[k] = new[k]
with open(target, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=indent)
    if raw.endswith("\n"):
        f.write("\n")
print("%s: %d claves nuevas, %d ya existian" % (target, len(added), len(new) - len(added)))
