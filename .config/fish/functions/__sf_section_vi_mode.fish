#
# Vi Mode
#

function __sf_section_vi_mode -d "Display vi mode status"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_VI_MODE_SHOW true
	__sf_util_set_default SPACEFISH_VI_MODE_PREFIX " "
	__sf_util_set_default SPACEFISH_VI_MODE_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_VI_MODE_INSERT [I]
	__sf_util_set_default SPACEFISH_VI_MODE_NORMAL [N]
	__sf_util_set_default SPACEFISH_VI_MODE_VISUAL [V]
	__sf_util_set_default SPACEFISH_VI_MODE_REPLACE_ONE [R]
	__sf_util_set_default SPACEFISH_VI_MODE_COLOR white

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	[ $SPACEFISH_VI_MODE_SHOW = false ]; and return

	# Ensure fish_vi_key_bindings or fish_hybrid_key_bindings are used
	# Here we are trying to be compatible with default fish_mode_prompt implementation,
	# wich handle both "fish_vi_key_bindings" and "fish_hybrid_key_bindings"
	[ "$fish_key_bindings" = "fish_vi_key_bindings" ]; or [ "$fish_key_bindings" = "fish_hybrid_key_bindings" ]; or return

	# Use `set -l` to define local variables to avoid populating
  	# the global namespace
	set -l vi_mode_symbol

	# Check current mode and set vi_mode_symbol based on it
	switch $fish_bind_mode
		case default
			set vi_mode_symbol $SPACEFISH_VI_MODE_NORMAL
		case insert
			set vi_mode_symbol $SPACEFISH_VI_MODE_INSERT
		case replace_one
			set vi_mode_symbol $SPACEFISH_VI_MODE_REPLACE_ONE
		case visual
			set vi_mode_symbol $SPACEFISH_VI_MODE_VISUAL
	end

	__sf_lib_section \
		$SPACEFISH_VI_MODE_COLOR \
		$SPACEFISH_VI_MODE_PREFIX \
		$vi_mode_symbol \
		$SPACEFISH_VI_MODE_SUFFIX
end
