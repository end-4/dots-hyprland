# virtualenv
#

function __sf_section_venv -d "Show current virtual Python environment"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_VENV_SHOW true
	__sf_util_set_default SPACEFISH_VENV_PREFIX $SPACEFISH_PROMPT_DEFAULT_PREFIX
	__sf_util_set_default SPACEFISH_VENV_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_VENV_SYMBOL "·"
	__sf_util_set_default SPACEFISH_VENV_GENERIC_NAMES virtualenv venv .venv
	__sf_util_set_default SPACEFISH_VENV_COLOR blue

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Show venv python version
	 test $SPACEFISH_VENV_SHOW = false; and return

	# Check if the current directory running via Virtualenv
	test -n "$VIRTUAL_ENV"; or return

	set -l venv (basename $VIRTUAL_ENV)
	if contains $venv $SPACEFISH_VENV_GENERIC_NAMES
		set venv (basename (dirname $VIRTUAL_ENV))
	end

	__sf_lib_section \
		$SPACEFISH_VENV_COLOR \
		$SPACEFISH_VENV_PREFIX \
		"$SPACEFISH_VENV_SYMBOL""$venv" \
		$SPACEFISH_VENV_SUFFIX
end
