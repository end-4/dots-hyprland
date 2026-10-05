#!/usr/bin/env python3
"""
Dynamic GPU and Display Connector Detector for Quickshell / Hyprland
Scans PCI bus, /sys/class/drm, and active drivers to report GPU architecture,
per-connector routing, and render-offload capabilities dynamically across any Linux hardware.
"""

import os
import sys
import subprocess
import json
import re

def get_clean_name(raw_name):
    cleaned = re.sub(r'\[[0-9a-fA-F:]+\]', '', raw_name)
    cleaned = re.sub(r'\(rev [0-9a-fA-F]+\)', '', cleaned)
    cleaned = re.sub(r'Corporation', '', cleaned)
    return ' '.join(cleaned.split()).strip()

def detect():
    data = {
        'primaryRenderer': '',
        'gpus': [],
        'connectors': {},
        'hasDgpu': False,
        'dgpu': None,
        'isHybrid': False,
        'offloadCommand': '',
        'offloadPrefix': ''
    }

    # 1. Query active OpenGL renderer via glxinfo if available
    try:
        glx = subprocess.check_output(['glxinfo', '-B'], text=True, stderr=subprocess.DEVNULL)
        for line in glx.splitlines():
            if 'OpenGL renderer string:' in line:
                data['primaryRenderer'] = line.split(':', 1)[1].strip()
    except Exception:
        pass

    # 2. Enumerate PCI graphics devices
    pci_gpus = {}
    try:
        lspci = subprocess.check_output(['lspci', '-nn'], text=True, stderr=subprocess.DEVNULL)
        for line in lspci.splitlines():
            if any(k in line for k in [' 0300: ', ' 0301: ', ' 0302: ', ' VGA compatible controller', ' 3D controller', ' Display controller']):
                slot = line.split()[0]
                full_slot = slot if slot.startswith('0000:') else f'0000:{slot}'
                desc = line.split(': ', 1)[-1]
                is_3d = ' 0302: ' in line or '3D controller' in line
                
                vendor = 'generic'
                low = line.lower()
                if '8086:' in low or 'intel' in low:
                    vendor = 'intel'
                elif '10de:' in low or 'nvidia' in low:
                    vendor = 'nvidia'
                elif '1002:' in low or 'amd' in low or 'ati' in low:
                    vendor = 'amd'
                
                driver = 'unknown'
                uevent_file = f'/sys/bus/pci/devices/{full_slot}/uevent'
                if os.path.exists(uevent_file):
                    with open(uevent_file) as f:
                        for uline in f:
                            if uline.startswith('DRIVER='):
                                driver = uline.strip().split('=')[1]

                info = {
                    'pci': full_slot,
                    'rawName': desc,
                    'name': get_clean_name(desc),
                    'vendor': vendor,
                    'driver': driver,
                    'is3dOnly': is_3d,
                    'isKms': not is_3d
                }
                pci_gpus[full_slot] = info
                data['gpus'].append(info)
    except Exception:
        pass

    # 3. Scan /sys/class/drm connectors
    drm_path = '/sys/class/drm'
    if os.path.exists(drm_path):
        for entry in os.listdir(drm_path):
            if entry.startswith('card') and '-' in entry:
                card_name, conn_name = entry.split('-', 1)
                
                card_dev_path = os.path.realpath(f'{drm_path}/{card_name}/device')
                pci_slot = os.path.basename(card_dev_path)
                
                gpu_match = pci_gpus.get(pci_slot)
                gpu_title = gpu_match['name'] if gpu_match else card_name
                driver = gpu_match['driver'] if gpu_match else 'unknown'
                
                data['connectors'][conn_name] = {
                    'card': card_name,
                    'pci': pci_slot,
                    'driver': driver,
                    'gpuName': gpu_title,
                    'vendor': gpu_match['vendor'] if gpu_match else 'generic'
                }

    # 4. Check for secondary / dedicated GPU (NVIDIA or discrete AMD)
    for g in data['gpus']:
        if g['vendor'] == 'nvidia' or (g['is3dOnly'] and g['vendor'] != 'intel'):
            data['hasDgpu'] = True
            data['isHybrid'] = len(data['gpus']) > 1
            data['dgpu'] = g
            data['offloadCommand'] = 'prime-run <command>'
            data['offloadPrefix'] = 'prime-run '
            break
        elif len(data['gpus']) > 1 and g['vendor'] == 'amd':
            data['hasDgpu'] = True
            data['isHybrid'] = True
            data['dgpu'] = g
            data['offloadCommand'] = 'DRI_PRIME=1 <command>'
            data['offloadPrefix'] = 'DRI_PRIME=1 '

    # 5. Live Telemetry if NVIDIA is active
    if data['hasDgpu'] and data['dgpu']['vendor'] == 'nvidia':
        try:
            smi = subprocess.check_output(
                ['nvidia-smi', '--query-gpu=name,driver_version,memory.total,memory.used,temperature.gpu,power.draw,utilization.gpu', '--format=csv,noheader,nounits'],
                text=True, stderr=subprocess.DEVNULL
            ).strip()
            parts = [p.strip() for p in smi.split(',')]
            if len(parts) >= 7:
                data['dgpu']['name'] = parts[0]
                data['dgpu']['driverVersion'] = parts[1]
                data['dgpu']['vramTotal'] = f'{parts[2]} MB'
                data['dgpu']['vramUsed'] = f'{parts[3]} MB'
                data['dgpu']['temp'] = f'{parts[4]}°C'
                data['dgpu']['power'] = f'{round(float(parts[5]))}W'
                data['dgpu']['utilization'] = f'{parts[6]}%'
        except Exception:
            pass

    return data

if __name__ == '__main__':
    print(json.dumps(detect()))
