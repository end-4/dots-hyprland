#
# Haskell Stack
#
# An advanced, purely functional programming language.
# Link: https://www.haskell.org/

function __sf_section_haskell -d "Show current version of Haskell Tool Stack"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_HASKELL_SHOW true
	__sf_util_set_default SPACEFISH_HASKELL_PREFIX $SPACEFISH_PROMPT_DEFAULT_PREFIX
	__sf_util_set_default SPACEFISH_HASKELL_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_HASKELL_SYMBOL "λ "
	__sf_util_set_default SPACEFISH_HASKELL_COLOR red

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Show current version of Haskell Tool Stack.
	[ $SPACEFISH_HASKELL_SHOW = false ]; and return

	# Ensure the stack command is available
	type -q stack; or return

	# If there are stack files in current directory
	[ -f ./stack.yaml ]; or return

	set -l haskell_version (stack ghc -- --numeric-version --no-install-ghc)

	__sf_lib_section \
		$SPACEFISH_HASKELL_COLOR \
		$SPACEFISH_HASKELL_PREFIX \
		"$SPACEFISH_HASKELL_SYMBOL"v"$haskell_version" \
		$SPACEFISH_HASKELL_SUFFIX
end
