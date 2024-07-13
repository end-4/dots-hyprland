#
# Go
#
# Go is an open source programming language that makes it easy
# to build efficient software.
# Link: https://golang.org/

function __sf_section_golang -d "Display the current go version if you're inside GOPATH"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_GOLANG_SHOW true
	__sf_util_set_default SPACEFISH_GOLANG_PREFIX $SPACEFISH_PROMPT_DEFAULT_PREFIX
	__sf_util_set_default SPACEFISH_GOLANG_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_GOLANG_SYMBOL "🐹 "
	__sf_util_set_default SPACEFISH_GOLANG_COLOR cyan

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Show the current version of Golang
	[ $SPACEFISH_GOLANG_SHOW = false ]; and return

	# Ensure the go command is available
	type -q go; or return

	if not test -f go.mod \
		-o -d Godeps \
		-o -f glide.yaml \
		-o (count *.go) -gt 0 \
		-o -f Gopkg.yml \
		-o -f Gopkg.lock \
		-o ([ (count $GOPATH) -gt 0 ]; and string match $GOPATH $PWD)
		return
	end

	set -l go_version (go version | string split ' ')

	# Go version is either the commit hash and date (devel +5efe9a8f11 Web Jan 9 07:21:16 2019 +0000)
	# at the time of the build or a release tag (go1.11.4)
	# https://github.com/matchai/spacefish/issues/137
	if test (string match 'devel*' $go_version[3])
		set go_version $go_version[3]":"(string sub -s 2 $go_version[4])
	else
		set go_version "v"(string sub -s 3 $go_version[3])
	end

	__sf_lib_section \
		$SPACEFISH_GOLANG_COLOR \
		$SPACEFISH_GOLANG_PREFIX \
		"$SPACEFISH_GOLANG_SYMBOL""$go_version" \
		$SPACEFISH_GOLANG_SUFFIX
end
