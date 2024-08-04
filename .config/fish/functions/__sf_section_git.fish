#
# Git
#

function __sf_section_git -d "Display the git branch and status"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_GIT_SHOW true
	__sf_util_set_default SPACEFISH_GIT_PREFIX "on "
	__sf_util_set_default SPACEFISH_GIT_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_GIT_SYMBOL " "

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Show both git branch and git status:
	#   spacefish_git_branch
	#   spacefish_git_status

	[ $SPACEFISH_GIT_SHOW = false ]; and return

	set -l git_branch (__sf_section_git_branch)
	set -l git_status (__sf_section_git_status)

	[ -z $git_branch ]; and return

	__sf_lib_section \
		fff \
		$SPACEFISH_GIT_PREFIX \
		"$git_branch$git_status" \
		$SPACEFISH_GIT_SUFFIX
end
