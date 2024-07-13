# pyenv
#

function __sf_section_pyenv -d "Show current version of pyenv Python, including system."
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_PYENV_SHOW true
	__sf_util_set_default SPACEFISH_PYENV_PREFIX $SPACEFISH_PROMPT_DEFAULT_PREFIX
	__sf_util_set_default SPACEFISH_PYENV_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_PYENV_SYMBOL "🐍 "
	__sf_util_set_default SPACEFISH_PYENV_COLOR yellow

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Show pyenv python version
	[ $SPACEFISH_PYENV_SHOW = false ]; and return

	# Ensure the pyenv command is available
	type -q pyenv; or return

	# Show pyenv python version only for Python-specific folders
	if not test -n "$PYENV_VERSION" \
		-o -f .python-version \
		-o -f requirements.txt \
		-o -f pyproject.toml \
		-o (count *.py) -gt 0
		return
	end

	set -l pyenv_status (pyenv version-name 2>/dev/null) # This line needs explicit testing in an enviroment that has pyenv.

	__sf_lib_section \
		$SPACEFISH_PYENV_COLOR \
		$SPACEFISH_PYENV_PREFIX \
		"$SPACEFISH_PYENV_SYMBOL""$pyenv_status" \
		$SPACEFISH_PYENV_SUFFIX
end
