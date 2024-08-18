[iterm2-themes]: https://github.com/mbadolato/iTerm2-Color-Schemes
[color-scripts]: https://github.com/stark/Color-Scripts/tree/master/color-scripts
[license]: https://opensource.org/licenses/MIT
[license-badge]:  https://img.shields.io/github/license/dexpota/kitty-themes.svg?style=for-the-badge
[kitty-themes-previews]: https://github.com/dexpota/kitty-themes-website/tree/master/previews

![kitty-themes](./.github/kitty-themes.jpg)

> **Personalize** your *kitty* terminal and choose your theme from this awesome
> collection, for more information on the terminal visit
> https://github.com/kovidgoyal/kitty

[![License: MIT][license-badge]][license]
[![All Contributors](https://img.shields.io/badge/all_contributors-9-green.svg?style=for-the-badge)](#contributors)

- [About](#about)
- [Installation](#installation)
  - [Source Code](#source-code)
  - [Conda](#conda)
- [License](#license)
- [Bring me to the previews!](#previews)
- [Contributors](#contributors)

## About

In this repository you can find a set of themes to personalize your kitty
terminal, these have been ported from [iTerm2-Color-Schemes][iterm2-themes]. You can find
the previews for each theme in the [section](#previews) below or in this other
[repository](kitty-themes-previews).

## Installation

### Source Code

1. If you want to download and use one of these theme you have two options:
    - clone the entire *kitty-themes* repository:
      ```bash
      git clone --depth 1 https://github.com/dexpota/kitty-themes.git ~/.config/kitty/kitty-themes
      ```
   - or download just one theme:
      ```bash
      THEME=https://raw.githubusercontent.com/dexpota/kitty-themes/master/themes/3024_Day.conf
      wget "$THEME" -P ~/.config/kitty/kitty-themes/themes
      ```

2. Choose a theme and create a symlink:

    ```bash
    cd ~/.config/kitty
    ln -s ./kitty-themes/themes/Floraverse.conf ~/.config/kitty/theme.conf
    ```

3. Add this line to your kitty.conf configuration file:

    ```
    include ./theme.conf
    ```

### Conda

If you using the ``conda`` package manager, you may also install these themes
with the following command:

```bash
conda install -c conda-forge kitty-themes
```

## License

All original content of this repository is licensed with the [MIT
License](./LICENSE.md). Whenever possible the author of the theme is cited
inside each theme configuration file, together with its license. Hit me up if
you find your theme inside this repository and you want a proper citation.

## Previews

If you have followed the [installation](#installation) instructions and cloned
the entire repo, you have two options to try a theme:

1. If you have enabled remote control in *kitty* you can run this command:

    ```bash
    kitty @ set-colors -a "~/.config/kitty/kitty-themes/themes/AdventureTime.conf"
    ```

2. Otherwise you can start another instance of kitty and specify another config
  file to read from, this will cause *kitty* to read both its normal config
  file and the specified one:

    ```bash
    kitty -o include="~/.config/kitty/kitty-themes/themes/AdventureTime.conf"
    ```

### Bonus

Try your new theme with one of the scripts in [Color-scripts][color-scripts] with this
one-liner (requires `jq`):

```bash
COLOR_SCRIPT_REPO=https://api.github.com/repos/stark/Color-Scripts/contents/color-scripts
wget -q -O - $(curl -s $COLOR_SCRIPT_REPO | jq '.[] | "\(.path) \(.download_url)"' -r | shuf -n1 | cut -d " " -f2) | bash
```

### 3024 Day
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/3024_Day/preview.png)
### 3024 Night
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/3024_Night/preview.png)
### AdventureTime
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/AdventureTime/preview.png)
### Afterglow
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Afterglow/preview.png)
### AlienBlood
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/AlienBlood/preview.png)
### Alucard
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Alucard/preview.png)
### Apprentice
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Apprentice/preview.png)
### Argonaut
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Argonaut/preview.png)
### Arthur
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Arthur/preview.png)
### AtelierSulphurpool
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/AtelierSulphurpool/preview.png)
### Atom
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Atom/preview.png)
### AtomOneLight
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/AtomOneLight/preview.png)
### ayu
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/ayu/preview.png)
### ayu light
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/ayu_light/preview.png)
### ayu mirage
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/ayu_mirage/preview.png)
### Batman
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Batman/preview.png)
### Belafonte Day
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Belafonte_Day/preview.png)
### Belafonte Night
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Belafonte_Night/preview.png)
### BirdsOfParadise
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/BirdsOfParadise/preview.png)
### Blazer
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Blazer/preview.png)
### Borland
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Borland/preview.png)
### Bright Lights
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Bright_Lights/preview.png)
### Broadcast
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Broadcast/preview.png)
### Brogrammer
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Brogrammer/preview.png)
### C64
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/C64/preview.png)
### Chalk
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Chalk/preview.png)
### Chalkboard
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Chalkboard/preview.png)
### Ciapre
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Ciapre/preview.png)
### CLRS
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/CLRS/preview.png)
### Cobalt2
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Cobalt2/preview.png)
### Cobalt Neon
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Cobalt_Neon/preview.png)
### CrayonPonyFish
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/CrayonPonyFish/preview.png)
### Dark Pastel
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Dark_Pastel/preview.png)
### Darkside
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Darkside/preview.png)
### Desert
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Desert/preview.png)
### DimmedMonokai
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/DimmedMonokai/preview.png)
### DotGov
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/DotGov/preview.png)
### Dracula
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Dracula/preview.png)
### Dumbledore
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Dumbledore/preview.png)
### Duotone Dark
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Duotone_Dark/preview.png)
### Earthsong
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Earthsong/preview.png)
### Elemental
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Elemental/preview.png)
### ENCOM
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/ENCOM/preview.png)
### Espresso
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Espresso/preview.png)
### Espresso Libre
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Espresso_Libre/preview.png)
### Fideloper
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Fideloper/preview.png)
### FishTank
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/FishTank/preview.png)
### Flat
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Flat/preview.png)
### Flatland
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Flatland/preview.png)
### Floraverse
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Floraverse/preview.png)
### FrontEndDelight
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/FrontEndDelight/preview.png)
### FunForrest
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/FunForrest/preview.png)
### Galaxy
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Galaxy/preview.png)
### Github
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Github/preview.png)
### Glacier
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Glacier/preview.png)
### GoaBase
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/GoaBase/preview.png)
### Grape
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Grape/preview.png)
### Grass
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Grass/preview.png)
### gruvbox dark
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/gruvbox_dark/preview.png)
### gruvbox light
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/gruvbox_light/preview.png)
### Hardcore
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Hardcore/preview.png)
### Harper
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Harper/preview.png)
### Highway
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Highway/preview.png)
### Hipster Green
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Hipster_Green/preview.png)
### Homebrew
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Homebrew/preview.png)
### Hurtado
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Hurtado/preview.png)
### Hybrid
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Hybrid/preview.png)
### IC Green PPL
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/IC_Green_PPL/preview.png)
### IC Orange PPL
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/IC_Orange_PPL/preview.png)
### idleToes
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/idleToes/preview.png)
### IR Black
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/IR_Black/preview.png)
### Jackie Brown
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Jackie_Brown/preview.png)
### Japanesque
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Japanesque/preview.png)
### Jellybeans
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Jellybeans/preview.png)
### JetBrains Darcula
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/JetBrains_Darcula/preview.png)
### Kibble
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Kibble/preview.png)
### Later This Evening
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Later_This_Evening/preview.png)
### Lavandula
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Lavandula/preview.png)
### LiquidCarbon
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/LiquidCarbon/preview.png)
### LiquidCarbonTransparent
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/LiquidCarbonTransparent/preview.png)
### LiquidCarbonTransparentInverse
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/LiquidCarbonTransparentInverse/preview.png)
### Man Page
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Man_Page/preview.png)
### Material
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Material/preview.png)
### MaterialDark
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/MaterialDark/preview.png)
### Mathias
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Mathias/preview.png)
### Medallion
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Medallion/preview.png)
### Misterioso
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Misterioso/preview.png)
### Molokai
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Molokai/preview.png)
### MonaLisa
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/MonaLisa/preview.png)
### Monokai Classic
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Monokai_Classic/preview.png)
### Monokai Pro
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Monokai_Pro/preview.png)
### Monokai Pro (Filter Machine)
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Monokai_Pro_(Filter_Machine)/preview.png)
### Monokai Pro (Filter Octagon)
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Monokai_Pro_(Filter_Octagon)/preview.png)
### Monokai Pro (Filter Ristretto)
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Monokai_Pro_(Filter_Ristretto)/preview.png)
### Monokai Pro (Filter Spectrum)
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Monokai_Pro_(Filter_Spectrum)/preview.png)
### Monokai Soda
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Monokai_Soda/preview.png)
### N0tch2k
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/N0tch2k/preview.png)
### Neopolitan
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Neopolitan/preview.png)
### Neutron
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Neutron/preview.png)
### NightLion v1
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/NightLion_v1/preview.png)
### NightLion v2
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/NightLion_v2/preview.png)
### Nova
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Nova/preview.png)
### Novel
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Novel/preview.png)
### Obsidian
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Obsidian/preview.png)
### Ocean
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Ocean/preview.png)
### OceanicMaterial
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/OceanicMaterial/preview.png)
### Ollie
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Ollie/preview.png)
### OneDark
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/OneDark/preview.png)
### Parasio Dark
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Parasio_Dark/preview.png)
### PaulMillr
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/PaulMillr/preview.png)
### PencilDark
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/PencilDark/preview.png)
### PencilLight
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/PencilLight/preview.png)
### Piatto Light
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Piatto_Light/preview.png)
### Pnevma
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Pnevma/preview.png)
### Pro
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Pro/preview.png)
### Red Alert
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Red_Alert/preview.png)
### Red Sands
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Red_Sands/preview.png)
### Relaxed Afterglow
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Relaxed_Afterglow/preview.png)
### Renault Style
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Renault_Style/preview.png)
### Renault Style Light
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Renault_Style_Light/preview.png)
### Rippedcasts
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Rippedcasts/preview.png)
### Royal
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Royal/preview.png)
### Seafoam Pastel
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Seafoam_Pastel/preview.png)
### SeaShells
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/SeaShells/preview.png)
### Seti
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Seti/preview.png)
### Shaman
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Shaman/preview.png)
### Slate
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Slate/preview.png)
### Smyck
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Smyck/preview.png)
### snazzy
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/snazzy/preview.png)
### SoftServer
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/SoftServer/preview.png)
### Solarized Darcula
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Solarized_Darcula/preview.png)
### Solarized Dark
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Solarized_Dark/preview.png)
### Solarized Dark Higher Contrast
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Solarized_Dark_Higher_Contrast/preview.png)
### Solarized Dark - Patched
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Solarized_Dark_-_Patched/preview.png)
### Solarized Light
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Solarized_Light/preview.png)
### Source Code X
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Source_Code_X/preview.png)
### Spacedust
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Spacedust/preview.png)
### SpaceGray
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/SpaceGray/preview.png)
### SpaceGray Eighties
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/SpaceGray_Eighties/preview.png)
### SpaceGray Eighties Dull
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/SpaceGray_Eighties_Dull/preview.png)
### Spiderman
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Spiderman/preview.png)
### Spring
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Spring/preview.png)
### Square
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Square/preview.png)
### Sundried
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Sundried/preview.png)
### Symfonic
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Symfonic/preview.png)
### Tango Dark
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Tango_Dark/preview.png)
### Tango Light
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Tango_Light/preview.png)
### Teerb
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Teerb/preview.png)
### Thayer Bright
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Thayer_Bright/preview.png)
### The Hulk
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/The_Hulk/preview.png)
### Tomorrow
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Tomorrow/preview.png)
### Tomorrow Night
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Tomorrow_Night/preview.png)
### Tomorrow Night Blue
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Tomorrow_Night_Blue/preview.png)
### Tomorrow Night Bright
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Tomorrow_Night_Bright/preview.png)
### Tomorrow Night Eighties
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Tomorrow_Night_Eighties/preview.png)
### ToyChest
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/ToyChest/preview.png)
### Treehouse
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Treehouse/preview.png)
### Twilight
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Twilight/preview.png)
### Ubuntu
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Ubuntu/preview.png)
### Urple
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Urple/preview.png)
### Vaughn
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Vaughn/preview.png)
### VibrantInk
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/VibrantInk/preview.png)
### WarmNeon
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/WarmNeon/preview.png)
### Wez
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Wez/preview.png)
### WildCherry
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/WildCherry/preview.png)
### Wombat
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Wombat/preview.png)
### Wryan
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Wryan/preview.png)
### Zenburn
![image](https://raw.githubusercontent.com/dexpota/kitty-themes-website/master/previews/Zenburn/preview.png)

## Contributors

Thanks goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore -->
<table>
  <tr>
    <td align="center"><a href="http://www.scopatz.com"><b>Anthony Scopatz</b></a><br /><a href="https://github.com/dexpota/kitty-themes/commits?author=scopatz" title="Documentation">📖</a></td>
    <td align="center"><a href="https://rckt.cc"><b>RCKT</b></a><br /><a href="#theme-orangecoloured" title="New theme added to the collection">😻</a></td>
    <td align="center"><a href="https://github.com/varmanishant"><b>varmanishant</b></a><br /><a href="#theme-varmanishant" title="New theme added to the collection">😻</a></td>
    <td align="center"><a href="https://github.com/rlerdorf"><b>Rasmus Lerdorf</b></a><br /><a href="https://github.com/dexpota/kitty-themes/issues?q=author%3Arlerdorf" title="Bug reports">🐛</a> <a href="#ideas-rlerdorf" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/Luflosi"><b>Luflosi</b></a><br /><a href="#fix-Luflosi" title="Fixed a theme">🛠️</a> <a href="#question-Luflosi" title="Answering Questions">💬</a> <a href="https://github.com/dexpota/kitty-themes/commits?author=Luflosi" title="Documentation">📖</a></td>
    <td align="center"><a href="https://holyday.me"><b>Connor Holyday</b></a><br /><a href="#fix-connorholyday" title="Fixed a theme">🛠️</a></td>
    <td align="center"><a href="https://github.com/BlueDrink9"><b>BlueDrink9</b></a><br /><a href="https://github.com/dexpota/kitty-themes/issues?q=author%3ABlueDrink9" title="Bug reports">🐛</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/brujoand"><b>Anders Brujordet</b></a><br /><a href="#theme-brujoand" title="New theme added to the collection">😻</a></td>
    <td align="center"><a href="http://www.hackouts.com"><b>Rajesh Rajendran</b></a><br /><a href="#fix-rjshrjndrn" title="Fixed a theme">🛠️</a></td>
  </tr>
</table>

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!
