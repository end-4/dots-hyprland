#
# Time
#

function __sf_section_time -d "Display the current time!"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_TIME_SHOW false
	__sf_util_set_default SPACEFISH_DATE_SHOW false
	__sf_util_set_default SPACEFISH_TIME_PREFIX "at "
	__sf_util_set_default SPACEFISH_TIME_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_TIME_FORMAT false
	__sf_util_set_default SPACEFISH_TIME_12HR false
	__sf_util_set_default SPACEFISH_TIME_COLOR "yellow"

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	[ $SPACEFISH_TIME_SHOW = false ]; and return

	set -l time_str

	if test $SPACEFISH_DATE_SHOW = true
		set time_str (date '+%Y-%m-%d')" "
	end

	if not test $SPACEFISH_TIME_FORMAT = false
		set time_str "$time_str"(date '+'$SPACEFISH_TIME_FORMAT)
	else if test $SPACEFISH_TIME_12HR = true
		set time_str "$time_str"(date '+%I:%M:%S') # Fish doesn't seem to have date/time formatting.
	else
		set time_str "$time_str"(date '+%H:%M:%S')
	end

	__sf_lib_section \
		$SPACEFISH_TIME_COLOR \
		$SPACEFISH_TIME_PREFIX \
		$time_str \
		$SPACEFISH_TIME_SUFFIX
end
