#
# Ruby
#
# A dynamic, reflective, object-oriented, general-purpose programming language.
# Link: https://www.ruby-lang.org/

function __sf_section_ruby -d "Show current version of Ruby"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_RUBY_SHOW true
	__sf_util_set_default SPACEFISH_RUBY_PREFIX $SPACEFISH_PROMPT_DEFAULT_PREFIX
	__sf_util_set_default SPACEFISH_RUBY_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_RUBY_SYMBOL "💎 "
	__sf_util_set_default SPACEFISH_RUBY_COLOR red

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Check if that user wants to show ruby version
	[ $SPACEFISH_RUBY_SHOW = false ]; and return

	# Show versions only for Ruby-specific folders
	if not test -f Gemfile \
		-o -f Rakefile \
		-o (count *.rb) -gt 0
		return
	end

	set -l ruby_version

	if type -q rvm-prompt
		set ruby_version (rvm-prompt i v g)
	else if type -q rbenv
		set ruby_version (rbenv version-name)
	else if type -q chruby
		set ruby_version $RUBY_AUTO_VERSION
	else if type -q asdf
		set ruby_version (asdf current ruby | awk '{print $1}')
	else
		return
	end

	[ -z "$ruby_version" -o "$ruby_version" = "system" ]; and return

	# Add 'v' before ruby version that starts with a number
	if test -n (echo (string match -r "^[0-9].+\$" "$ruby_version"))
		set ruby_version "v$ruby_version"
	end

	__sf_lib_section \
		$SPACEFISH_RUBY_COLOR \
		$SPACEFISH_RUBY_PREFIX \
		"$SPACEFISH_RUBY_SYMBOL""$ruby_version" \
		$SPACEFISH_RUBY_SUFFIX
end
