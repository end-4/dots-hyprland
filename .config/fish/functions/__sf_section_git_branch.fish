#
# Git branch
#

function __sf_section_git_branch -d "Format the displayed branch name"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_GIT_BRANCH_SHOW true
	__sf_util_set_default SPACEFISH_GIT_BRANCH_PREFIX $SPACEFISH_GIT_SYMBOL
	__sf_util_set_default SPACEFISH_GIT_BRANCH_SUFFIX ""
	__sf_util_set_default SPACEFISH_GIT_BRANCH_COLOR magenta

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	[ $SPACEFISH_GIT_BRANCH_SHOW = false ]; and return

	set -l git_branch (__sf_util_git_branch)

	[ -z $git_branch ]; and return

	__sf_lib_section \
		$SPACEFISH_GIT_BRANCH_COLOR \
		$SPACEFISH_GIT_BRANCH_PREFIX$git_branch$SPACEFISH_GIT_BRANCH_SUFFIX
end
