# Eww configuration

This configuration aims to provide a fully working shell replacement for
compositors/window managers. Features constantly get added and existing ones
get improved.

## 🗃️  Components

The same daemon runs multiple windows which interact with each other:

### bar

![bar](https://user-images.githubusercontent.com/36706276/192146060-9913d571-abee-4683-9f77-ea1951680cc1.gif)

### music window

![music](https://user-images.githubusercontent.com/36706276/192146077-f8da4691-9a0c-487f-9805-3fd4d55551e9.gif)

### calendar

![calendar](https://user-images.githubusercontent.com/36706276/204923748-f5c7db3a-5000-40cf-ba41-cd2d5f14146a.png)

### system info

![system](https://user-images.githubusercontent.com/36706276/204923681-13c6e1d6-45e8-4f23-aec9-dcd8b96203da.png)

## ❔ Usage

To quickly install this config, grab all the files in this directory and put
them in `~/.config/eww`. Then run `eww daemon` and `eww open bar`. Enjoy!

Dependencies:
- Icon fonts: `material-design-icons`, `material-icons`
- Text font: Product Sans
- Script deps: everything in `default.nix`'s `dependencies` list.

## 🎨 Theme

The theme colors can be changed in `css/_colors.scss`. Currently the theme used
is [Catppuccin Mocha](https://github.com/catppuccin/catppuccin).
