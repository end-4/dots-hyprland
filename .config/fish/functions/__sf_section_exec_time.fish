#
# Execution time
#

function __sf_section_exec_time -d "Display the execution time of the last command"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_EXEC_TIME_SHOW true
	__sf_util_set_default SPACEFISH_EXEC_TIME_PREFIX "took "
	__sf_util_set_default SPACEFISH_EXEC_TIME_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_EXEC_TIME_COLOR yellow
	__sf_util_set_default SPACEFISH_EXEC_TIME_ELAPSED 5

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	[ $SPACEFISH_EXEC_TIME_SHOW = false ]; and return

	# Allow for compatibility between fish 2.7 and 3.0
	set -l command_duration "$CMD_DURATION$cmd_duration"

	if test -n "$command_duration" -a "$command_duration" -gt (math "$SPACEFISH_EXEC_TIME_ELAPSED * 1000")
		set -l human_command_duration (echo $command_duration | __sf_util_human_time)
		__sf_lib_section \
			$SPACEFISH_EXEC_TIME_COLOR \
			$SPACEFISH_EXEC_TIME_PREFIX \
			$human_command_duration \
			$SPACEFISH_EXEC_TIME_SUFFIX
	end
end
