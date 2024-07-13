#
#  Kubernetes (kubectl)
#
# Kubernetes is an open-source system for deployment, scaling,
# and management of containerized applications.
# Link: https://kubernetes.io/

function __sf_section_kubecontext -d "Display the kubernetes context"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_KUBECONTEXT_SHOW true
	__sf_util_set_default SPACEFISH_KUBECONTEXT_NAMESPACE_SHOW true
	__sf_util_set_default SPACEFISH_KUBECONTEXT_PREFIX "at "
	__sf_util_set_default SPACEFISH_KUBECONTEXT_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	# Additional space is added because ☸️ is wider than other symbols
	# See: https://github.com/denysdovhan/spaceship-prompt/pull/432
	__sf_util_set_default SPACEFISH_KUBECONTEXT_SYMBOL "☸️  "
	__sf_util_set_default SPACEFISH_KUBECONTEXT_COLOR cyan


	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Show current kubecontext
	[ $SPACEFISH_KUBECONTEXT_SHOW = false ]; and return
	# Ensure the kubectl command is available
	type -q kubectl; or return

	set -l kube_context (kubectl config current-context 2>/dev/null)
	[ -z $kube_context ]; and return

	if test "$SPACEFISH_KUBECONTEXT_NAMESPACE_SHOW" = "true" -a "$kube_context" != "default"
		set kube_namespace (kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
		set kube_context "$kube_context ($kube_namespace)"
	end

	__sf_lib_section \
		$SPACEFISH_KUBECONTEXT_COLOR \
		$SPACEFISH_KUBECONTEXT_PREFIX \
		"$SPACEFISH_KUBECONTEXT_SYMBOL""$kube_context" \
		$SPACEFISH_KUBECONTEXT_SUFFIX
end
