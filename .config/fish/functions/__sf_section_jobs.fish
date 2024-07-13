# Jobs
#

function __sf_section_jobs -d "Show icon, if there's a working jobs in the background."
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_JOBS_SHOW true
	__sf_util_set_default SPACEFISH_JOBS_PREFIX ""
	__sf_util_set_default SPACEFISH_JOBS_SUFFIX " "
	__sf_util_set_default SPACEFISH_JOBS_SYMBOL ✦
	__sf_util_set_default SPACEFISH_JOBS_COLOR blue
	__sf_util_set_default SPACEFISH_JOBS_AMOUNT_PREFIX ""
	__sf_util_set_default SPACEFISH_JOBS_AMOUNT_SUFFIX ""
	__sf_util_set_default SPACEFISH_JOBS_AMOUNT_THRESHOLD 1

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	[ $SPACEFISH_JOBS_SHOW = false ]; and return

	set jobs_amount (jobs | wc -l | xargs) # Zsh had a much more complicated command.

	if test $jobs_amount -eq 0
		return
	end

	if test $jobs_amount -le $SPACEFISH_JOBS_AMOUNT_THRESHOLD
		set jobs_amount ''
		set SPACEFISH_JOBS_AMOUNT_PREFIX ''
		set SPACEFISH_JOBS_AMOUNT_SUFFIX ''
	end

	set SPACEFISH_JOBS_SECTION "$SPACEFISH_JOBS_SYMBOL$SPACEFISH_JOBS_AMOUNT_PREFIX$jobs_amount$SPACEFISH_JOBS_AMOUNT_SUFFIX"

	__sf_lib_section \
		$SPACEFISH_JOBS_COLOR \
		$SPACEFISH_JOBS_PREFIX \
		$SPACEFISH_JOBS_SECTION \
		$SPACEFISH_JOBS_SUFFIX
end
