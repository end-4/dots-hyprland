#
# Docker
#
# Current Docker version and Machine name.

function __sf_section_docker -d "Display docker version and machine name"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_DOCKER_SHOW true
	__sf_util_set_default SPACEFISH_DOCKER_PREFIX "is "
	__sf_util_set_default SPACEFISH_DOCKER_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_DOCKER_SYMBOL "🐳 "
	__sf_util_set_default SPACEFISH_DOCKER_COLOR cyan
	__sf_util_set_default SPACEFISH_DOCKER_VERBOSE_VERSION false

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	[ $SPACEFISH_DOCKER_SHOW = false ]; and return

	# Show Docker version only if docker is installed
	type -q docker; or return

	# Show docker version only when pwd has Dockerfile, docker-compose.yml, .dockerenv in root or COMPOSE_FILE
	if not test -f Dockerfile \
		-o -f docker-compose.yml \
		-o -f /.dockerenv \
		-o -f "$COMPOSE_FILE"
		return
	end

	set -l docker_version (docker version -f "{{.Server.Version}}" 2>/dev/null)
	# if docker daemon isn't running you'll get an error like 'Bad response from Docker engine'
	[ -z $docker_version ]; and return

	if test "$SPACEFISH_DOCKER_VERBOSE_VERSION" = "false"
			set docker_version (string split - $docker_version)[1]
	end

	if test -n "$DOCKER_MACHINE_NAME"
			set docker_version $docker_version via $DOCKER_MACHINE_NAME
	end

	__sf_lib_section \
	$SPACEFISH_DOCKER_COLOR \
	$SPACEFISH_DOCKER_PREFIX \
	"$SPACEFISH_DOCKER_SYMBOL"v"$docker_version" \
	$SPACEFISH_DOCKER_SUFFIX
end
