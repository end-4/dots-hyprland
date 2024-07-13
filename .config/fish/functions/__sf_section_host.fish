#
# Hostname
#


# If there is an ssh connections, current machine name.
function __sf_section_host -d "Display the current hostname if connected over SSH"

	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_HOST_SHOW true
	__sf_util_set_default SPACEFISH_HOST_PREFIX "at "
	__sf_util_set_default SPACEFISH_HOST_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_HOST_COLOR blue
	__sf_util_set_default SPACEFISH_HOST_COLOR_SSH green

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	[ "$SPACEFISH_HOST_SHOW" = false ]; and return

	if test "$SPACEFISH_HOST_SHOW" = "always"; or set -q SSH_CONNECTION;

		# Determination of what color should be used
		set -l host_color
		if set -q SSH_CONNECTION;
			set host_color $SPACEFISH_HOST_COLOR_SSH
		else
			set host_color $SPACEFISH_HOST_COLOR
		end

		__sf_lib_section \
			$host_color \
			$SPACEFISH_HOST_PREFIX \
			(hostname) \
			$SPACEFISH_HOST_SUFFIX
		end
end
