#
# Line separator
#

function __sf_section_line_sep -d "Separate the prompt into two lines"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_PROMPT_SEPARATE_LINE true

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	if test "$SPACEFISH_PROMPT_SEPARATE_LINE" = "true"
		echo -e -n \n
	end
end
