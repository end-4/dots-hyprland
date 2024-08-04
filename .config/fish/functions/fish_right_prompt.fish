function fish_right_prompt

	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_RPROMPT_ORDER ""

	# ------------------------------------------------------------------------------
	# Sections
	# ------------------------------------------------------------------------------

	[ -n "$SPACEFISH_RPROMPT_ORDER" ]; or return

	for i in $SPACEFISH_RPROMPT_ORDER
		eval __sf_section_$i
	end
	set_color normal
end
