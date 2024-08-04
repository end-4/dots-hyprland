# Exit-code
#

function __sf_section_exit_code -d "Shows the exit code from the previous command."
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_EXIT_CODE_SHOW false
	__sf_util_set_default SPACEFISH_EXIT_CODE_PREFIX ""
	__sf_util_set_default SPACEFISH_EXIT_CODE_SUFFIX " "
	__sf_util_set_default SPACEFISH_EXIT_CODE_SYMBOL ✘
	__sf_util_set_default SPACEFISH_EXIT_CODE_COLOR red

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	[ $SPACEFISH_EXIT_CODE_SHOW = false ]; or test $sf_exit_code -eq 0; and return

	__sf_lib_section \
		$SPACEFISH_EXIT_CODE_COLOR \
		$SPACEFISH_EXIT_CODE_PREFIX \
		"$SPACEFISH_EXIT_CODE_SYMBOL$sf_exit_code" \
		$SPACEFISH_EXIT_CODE_SUFFIX
end
