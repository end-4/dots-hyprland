## Why is this important?
Instead of installing python packages via system package manager, we should install them into virtual environment.

This is important because there has been so many complaints about the failure installing/updating python packages via system package manager, see [#1017](https://github.com/end-4/dots-hyprland/issues/1017).

## How to add/remove python package?

1. Edit `requirements.in`. You may refer to [PyPI](https://pypi.org/) for possible package names.
  - If PyPI does not have the needed package, we probably need to build it manually inside the venv. In such case we need to edit the install scripts.
2. Run `uv pip compile requirements.in -o requirements.txt` in this folder.

**Notes:**
- For reference see [uv doc](https://docs.astral.sh/uv/pip/dependencies/#using-requirementsin).
- `requirements.txt` is included in Git. It's for locking package versions to enhance stability and reproducibility.[^1]

[^1]: In fact, including package version lock file in Git is also the most common way for similar situations, for example the `package-lock.json` of Node.js projects (see also [this stackoverflow question](https://stackoverflow.com/questions/48524417/should-the-package-lock-json-file-be-added-to-gitignore)). Although there are some situations when it's not suitable to include the lock file, for example [the poetry document](https://python-poetry.org/docs/basic-usage/#committing-your-poetrylock-file-to-version-control) recommend application developers to include package version lock file in Git, but library developers should consider more, such as not including the lock file or including it but refreshing regularly.

## How will the python packages get installed?

For summary:
- They will be installed to the virtual environment `$ILLOGICAL_IMPULSE_VIRTUAL_ENV`.
- The default value of `$ILLOGICAL_IMPULSE_VIRTUAL_ENV` is `$XDG_STATE_HOME/quickshell/.venv`.
  - The default value of `$XDG_STATE_HOME` is `$HOME/.local/state`.
- Currently we use `env = ILLOGICAL_IMPULSE_VIRTUAL_ENV, ~/.local/state/quickshell/.venv` in `~/.config/hypr/hyprland/env.conf` to set this environment variable.[^2]

For details: see the function `install-python-packages()` defined in `/sdata/lib/package-installers.sh`.

[^2]: Hyprland seems to have weird problem dealing with recursive variable, so we can not use `$XDG_STATE_HOME/quickshell/.venv` even if we had set `$XDG_STATE_HOME` to `~/.local/state` explicitly, else `$XDG_STATE_HOME` will possibly not get expanded but get recognised as literally `$XDG_STATE_HOME`. This problem never happens for some users, but according to some issues when we were using recursive variable setting in the past, it's possible to happen for other users. Reason unknown.

## How to use the python packages installed through here?

Basically you'll need to activate the virtual environment first:
```bash
source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
```

It will add the python executable located in the venv to `$PATH` and give it the highest priority.
Run `which python` and you'll understand.

This python executable will also search and use the python package inside the venv,
which enables running any python script or running command provided via python package using the venv.

After that you probably need to deactivate it:
```bash
deactivate
```

### Situation 1: As a single command
**Description:** At someplace which accept a single command,
- run a python script,
- or run a command provided by python package.

Example: In `~/‎.config/quickshell/ii/screenshot.qml`:
```qml
Process {
id: imageDetectionProcess
                command: ["bash", "-c", `${Directories.scriptPath}/images/find_regions.py ` 
+ `--hyprctl ` 
+ `--image '${StringUtils.shellSingleQuoteEscape(panelWindow.screenshotPath)}' ` 
+ `--max-width ${Math.round(panelWindow.screen.width * root.falsePositivePreventionRatio)} ` 
```
In this example, python script `find_regions.py` is called and receives some arguments.

#### Solution A: shebang

Add the shebang below to the beginning of python script:
```python
#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""
```
And that's it!

**Note:** This is the simplest solution as it only modifies the shebang of python script.
**However:**
- It's only for python script, not the command provided by python package.
- It can not deal with complex argument (e.g. filename containing spaces) passed to the python script.
  - If we apply this solution to the example above, it may cause problem, considering that `--image '${StringUtils.shellSingleQuoteEscape(panelWindow.screenshotPath)}'` could be a rather complex argument passed to `find_regions.py`.
- This solution rely on shebang to activate the correct python venv, but the shebang will be ignored if the script is directly passed to the interpreter, e.g. `python3 foo.py`.

#### Solution B: bash script as wrapper

First make sure the python script is using the shebang `#!/usr/bin/env python3`, instead of `#!/usr/bin/python3` or something else.

Then write a wrapper script in bash.
Let's continue the `screenshot.qml` example, in the same directory as `find_regions.py`, write a `find-regions-venv.sh`:
```bash
#!/usr/bin/env bash

# Specify the path of the python script.
# The example below only applies when `find_regions.py` and this wrapper script are under the same folder.
PY_SCRIPT="$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)/find_regions.py"

source $(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate
"$PY_SCRIPT" "$@"
deactivate
```
**Not done yet!** Do not forget to update the code calling the original python script.
In this example, in `~/‎.config/quickshell/ii/screenshot.qml` we should modify `find_regions.py` to the wrapper script `find-regions-venv.sh`:
```qml
Process {
id: imageDetectionProcess
                command: ["bash", "-c", `${Directories.scriptPath}/images/find-regions-venv.sh ` 
+ `--hyprctl ` 
+ `--image '${StringUtils.shellSingleQuoteEscape(panelWindow.screenshotPath)}' ` 
+ `--max-width ${Math.round(panelWindow.screen.width * root.falsePositivePreventionRatio)} ` 
```

### Situation 2: Inside a bash script
Note: the solutions for `Situation 1: As a single command` also apply here; but **not** vice versa.

**Description:**
Inside a bash script,
- run a python script,
- or run a command provided by python package.

**Solution:**
- Add "activation command" before the target line,
- Also add "deactivation command" after the target line.

**Example:**

For running a python script,
take `generate_colors_material.py` as example:
```bash
source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
python3 "$SCRIPT_DIR/generate_colors_material.py" "${generate_colors_material_args[@]}" \
  > "$STATE_DIR"/user/generated/material_colors.scss
"$SCRIPT_DIR"/applycolor.sh
```

For running a python script provided by python package,
take `kde-material-you-colors` as example:
```bash
source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
kde-material-you-colors "$mode_flag" --color "$color" -sv "$sv_num"
deactivate
```



