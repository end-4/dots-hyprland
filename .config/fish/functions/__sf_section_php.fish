#
# PHP
#
# PHP is a server-side scripting language designed primarily for web development.
# Link: http://www.php.net/

function __sf_section_php -d "Display the current php version"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_PHP_SHOW true
	__sf_util_set_default SPACEFISH_PHP_PREFIX $SPACEFISH_PROMPT_DEFAULT_PREFIX
	__sf_util_set_default SPACEFISH_PHP_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_PHP_SYMBOL "🐘 "
	__sf_util_set_default SPACEFISH_PHP_COLOR blue

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Show current version of PHP
	[ $SPACEFISH_PHP_SHOW = false ]; and return

	# Ensure the php command is available
	type -q php; or return

	if not test -f composer.json \
		-o (count *.php) -gt 0
		return
	end

	set -l php_version (php -v | string match -r 'PHP\s*[0-9.]+' | string split ' ')[2]

	__sf_lib_section \
		$SPACEFISH_PHP_COLOR \
		$SPACEFISH_PHP_PREFIX \
		"$SPACEFISH_PHP_SYMBOL"v"$php_version" \
		$SPACEFISH_PHP_SUFFIX
end
