#!/bin/bash

vm=$1

virsh --connect=qemu:///system start $vm && sleep 2
virt-viewer --connect=qemu:///system --attach -f --hotkeys=toggle-fullscreen=shift+f11,release-cursor=shift+f12 $vm
