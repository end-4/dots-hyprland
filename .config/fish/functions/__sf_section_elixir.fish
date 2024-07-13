#
# Elixir
#
# A dynamic, reflective, object-oriented, general-purpose programming language.
# Link: https://www.elixir-lang.org/

function __sf_section_elixir -d "Show current version of Elixir"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_ELIXIR_SHOW true
	__sf_util_set_default SPACEFISH_ELIXIR_PREFIX $SPACEFISH_PROMPT_DEFAULT_PREFIX
	__sf_util_set_default SPACEFISH_ELIXIR_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_ELIXIR_SYMBOL "💧 "
	__sf_util_set_default SPACEFISH_ELIXIR_DEFAULT_VERSION $SPACEFISH_ELIXIR_DEFAULT_VERSION
	__sf_util_set_default SPACEFISH_ELIXIR_COLOR magenta

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Check if that user wants to show elixir version
	[ $SPACEFISH_ELIXIR_SHOW = false ]; and return

	# Show versions only for Elixir-specific folders
	if not test -f mix.exs \
		-o (count *.ex) -gt 0 \
		-o (count *.exs) -gt 0
		return
	end

	set -l elixir_version

	if type -q kiex
		set elixir_version $ELIXIR_VERSION
	else if type -q exenv
		set elixir_version (exenv version-name)
	else if type -q elixir
		set elixir_version (elixir -v 2>/dev/null | string match -r "Elixir.*" | string split " ")[2]
	else
		return
	end

	[ -z "$elixir_version" -o "$elixir_version" = "system" ]; and return

	# Add 'v' before elixir version that starts with a number
	if test -n (echo (string match -r "^[0-9].+\$" "$elixir_version"))
		set elixir_version "v$elixir_version"
	end

	__sf_lib_section \
		$SPACEFISH_ELIXIR_COLOR \
		$SPACEFISH_ELIXIR_PREFIX \
		"$SPACEFISH_ELIXIR_SYMBOL""$elixir_version" \
		$SPACEFISH_ELIXIR_SUFFIX
end
