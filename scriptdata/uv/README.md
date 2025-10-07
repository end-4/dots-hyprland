## How to add/remove python package?

1. Edit `requirements.in`. You may refer to [PyPI](https://pypi.org/) for possible package names.
   - See also [uv doc](https://docs.astral.sh/uv/pip/dependencies/#using-requirementsin).
2. Run `uv pip compile requirements.in -o requirements.txt` in this folder.

## How will the python packages get installed?

- They will be installed to the virtual environment `$ILLOGICAL_IMPULSE_VIRTUAL_ENV`.
- The default value of `$ILLOGICAL_IMPULSE_VIRTUAL_ENV` is `$XDG_STATE_HOME/quickshell/.venv`.
  - The default value of `$XDG_STATE_HOME` is `$HOME/.local/state`.
  - Currently we use `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV, ~/.local/state/quickshell/.venv` in `~/.config/hypr/hyprland/env.conf` to set this environment variable. Hyprland seems to have problem dealing with recursive variable so we can not use `$XDG_STATE_HOME/quickshell/.venv` (according to some issues when we were using AGS for illogical-impulse).
- See the function `install-python-packages()` defined in `/scriptdata/lib/package-installers.sh` for details.

## How to use the python packages installed through here?

Basically you'll need to activate the virtual environment first:
```bash
source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
```
then use the python package inside it;
After that you probably need to deactivate it:
```bash
deactivate
```
### Situation 1: Call the command directly
Take `kde-material-you-colors` as example.
```bash
source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
kde-material-you-colors "$mode_flag" --color "$color" -sv "$sv_num"
deactivate
```

### Situation 2: Use python script (wrapped)
Take `generate_colors_material.py` as example:
```bash
source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
python3 "$SCRIPT_DIR/generate_colors_material.py" "${generate_colors_material_args[@]}" \
  > "$STATE_DIR"/user/generated/material_colors.scss
"$SCRIPT_DIR"/applycolor.sh
```

### Situation 3: Use python script (shebang)
**Note**: This method is only for simple situation.
It can not deal with complex arguments (e.g. filaname containing spaces) passed to the python script.

Take `generate_colors_material.py` as example, add the shebang below to its beginning:
```python
#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
```
Then you should run the script directly, i.e. `./generate_colors_material.py`, **not** `python3 generate_colors_material.py`.
