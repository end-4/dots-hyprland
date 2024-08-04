#
# Amazon Web Services (AWS)
#
# The AWS Command Line Interface (CLI) is a unified tool to manage AWS services.
# Link: https://aws.amazon.com/cli/

function __sf_section_aws -d "Display the selected aws profile"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_AWS_SHOW true
	__sf_util_set_default SPACEFISH_AWS_PREFIX "using "
	__sf_util_set_default SPACEFISH_AWS_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_AWS_SYMBOL "☁️ "
	__sf_util_set_default SPACEFISH_AWS_COLOR ff8700

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Show the selected AWS-cli profile
	[ $SPACEFISH_AWS_SHOW = false ]; and return

	# Ensure the aws command is available
	type -q aws; or return

  set -l PROFILE_NAME
	
  # if aws-vault is in use, override profile with that
  if test -n "$AWS_VAULT"
    set PROFILE_NAME "$AWS_VAULT"
  else
    set PROFILE_NAME "$AWS_PROFILE"
  end

	# Early return if there's no named profile, or it's set to default
	if test -z "$PROFILE_NAME" \
		-o "$PROFILE_NAME" = "default"
		return
	end

	__sf_lib_section \
		$SPACEFISH_AWS_COLOR \
		$SPACEFISH_AWS_PREFIX \
		"$SPACEFISH_AWS_SYMBOL""$PROFILE_NAME" \
		$SPACEFISH_AWS_SUFFIX
end
