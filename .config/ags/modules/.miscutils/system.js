const { GLib } = imports.gi;
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync, exec } = Utils;

export const distroID = exec(`bash -c 'cat /etc/os-release | grep "^ID=" | cut -d "=" -f 2 | sed "s/\\"//g"'`).trim();
export const isDebianDistro = (distroID == 'linuxmint' || distroID == 'ubuntu' || distroID == 'debian' || distroID == 'zorin' || distroID == 'popos' || distroID == 'raspbian' || distroID == 'kali');
export const isArchDistro = (distroID == 'arch' || distroID == 'endeavouros' || distroID == 'cachyos');
export const hasFlatpak = !!exec(`bash -c 'command -v flatpak'`);

const LIGHTDARK_FILE_LOCATION = `${GLib.get_user_cache_dir()}/ags/user/colormode.txt`;
const colorMode = Utils.exec('bash -c "sed -n \'1p\' $HOME/.cache/ags/user/colormode.txt"');
export let darkMode = !(Utils.readFile(LIGHTDARK_FILE_LOCATION).split('\n')[0].trim() == 'light');
export const hasPlasmaIntegration = !!Utils.exec('bash -c "command -v plasma-browser-integration-host"');

export const getDistroIcon = () => {
    // Arches
    if(distroID == 'arch') return 'arch-symbolic';
    if(distroID == 'endeavouros') return 'endeavouros-symbolic';
    if(distroID == 'cachyos') return 'cachyos-symbolic';
    // Funny flake
    if(distroID == 'nixos') return 'nixos-symbolic';
    // Debians
    if(distroID == 'linuxmint') return 'ubuntu-symbolic';
    if(distroID == 'ubuntu') return 'ubuntu-symbolic';
    if(distroID == 'debian') return 'debian-symbolic';
    if(distroID == 'zorin') return 'ubuntu-symbolic';
    if(distroID == 'popos') return 'ubuntu-symbolic';
    if(distroID == 'raspbian') return 'debian-symbolic';
    if(distroID == 'kali') return 'debian-symbolic';
    return 'linux-symbolic';
}

export const getDistroName = () => {
    // Arches
    if(distroID == 'arch') return 'Arch Linux';
    if(distroID == 'endeavouros') return 'EndeavourOS';
    if(distroID == 'cachyos') return 'CachyOS';
    // Funny flake
    if(distroID == 'nixos') return 'NixOS';
    // Debians
    if(distroID == 'linuxmint') return 'Linux Mint';
    if(distroID == 'ubuntu') return 'Ubuntu';
    if(distroID == 'debian') return 'Debian';
    if(distroID == 'zorin') return 'Zorin';
    if(distroID == 'popos') return 'Pop!_OS';
    if(distroID == 'raspbian') return 'Raspbian';
    if(distroID == 'kali') return 'Kali Linux';
    return 'Linux';
}
