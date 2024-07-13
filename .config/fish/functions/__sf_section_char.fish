#
# Prompt character
#

function __sf_section_char -d "Display the prompt character"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_CHAR_PREFIX ""
	__sf_util_set_default SPACEFISH_CHAR_SUFFIX " "
	__sf_util_set_default SPACEFISH_CHAR_SYMBOL ➜
	__sf_util_set_default SPACEFISH_CHAR_COLOR_SUCCESS green
	__sf_util_set_default SPACEFISH_CHAR_COLOR_FAILURE red

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Color $SPACEFISH_CHAR_SYMBOL red if previous command failed and
	# color it in green if the command succeeded.
	set -l color

	if test $sf_exit_code -eq 0
		set color $SPACEFISH_CHAR_COLOR_SUCCESS
	else
		set color $SPACEFISH_CHAR_COLOR_FAILURE
	end

	__sf_lib_section \
		$color \
		$SPACEFISH_CHAR_PREFIX \
		$SPACEFISH_CHAR_SYMBOL \
		$SPACEFISH_CHAR_SUFFIX
end
