#
# Conda
#
# Current Conda version.

function __sf_section_conda -d "Display current Conda version"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_CONDA_SHOW true
	__sf_util_set_default SPACEFISH_CONDA_PREFIX $SPACEFISH_PROMPT_DEFAULT_PREFIX
	__sf_util_set_default SPACEFISH_CONDA_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_CONDA_SYMBOL "🅒 "
	__sf_util_set_default SPACEFISH_CONDA_COLOR blue

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	[ $SPACEFISH_CONDA_SHOW = false ]; and return

	# Show Conda version only if conda is installed and CONDA_DEFAULT_ENV is set
	if not type -q conda; \
		or test -z "$CONDA_DEFAULT_ENV";
		return
	end

	set -l conda_version (conda -V | string split ' ')[2]

	__sf_lib_section \
		$SPACEFISH_CONDA_COLOR \
		$SPACEFISH_CONDA_PREFIX \
		"$SPACEFISH_CONDA_SYMBOL"v"$conda_version" \
		$SPACEFISH_CONDA_SUFFIX
end
