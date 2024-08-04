#
# Julia
#
# Current Julia version.

function __sf_section_julia -d "Display julia version"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_JULIA_SHOW true
	__sf_util_set_default SPACEFISH_JULIA_PREFIX "is "
	__sf_util_set_default SPACEFISH_JULIA_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_JULIA_SYMBOL "ஃ "
	__sf_util_set_default SPACEFISH_JULIA_COLOR green

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	[ $SPACEFISH_JULIA_SHOW = false ]; and return

	# Show Julia version only if julia is installed
	type -q julia; or return

	# Show julia version only when pwd has *.jl file(s)
	[ (count *.jl) -gt 0 ]; or return

	set -l julia_version (julia --version | grep --color=never -oE '[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]')

	__sf_lib_section \
	$SPACEFISH_JULIA_COLOR \
	$SPACEFISH_JULIA_PREFIX \
	"$SPACEFISH_JULIA_SYMBOL"v"$julia_version" \
	$SPACEFISH_JULIA_SUFFIX
end
