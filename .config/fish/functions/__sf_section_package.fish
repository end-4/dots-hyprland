#
# Package
#
# Current package version.
# These package managers supported:
#   * NPM
#   * Cargo

function __sf_section_package -d "Display the local package version"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_PACKAGE_SHOW true
	__sf_util_set_default SPACEFISH_PACKAGE_PREFIX "is "
	__sf_util_set_default SPACEFISH_PACKAGE_SUFFIX $SPACEFISH_PROMPT_DEFAULT_SUFFIX
	__sf_util_set_default SPACEFISH_PACKAGE_SYMBOL "📦 "
	__sf_util_set_default SPACEFISH_PACKAGE_COLOR red

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	[ $SPACEFISH_PACKAGE_SHOW = false ]; and return

	# Exit if there is no package.json or Cargo.toml
	if not test -e ./package.json; and not test -e ./Cargo.toml
		return
	end

	set -l package_version

	# Check if package.json exists AND npm exists locally while supressing output to just exit code (-q)
	if type -q npm; and test -f ./package.json
		# Check if jq (json handler) exists locally. If yes, check in package.json version
		if type -q jq
			set package_version (jq -r '.version' package.json 2>/dev/null)
		# Check if python exists locally, use json to check version in package.json
		else if type -q python
			set package_version (python -c "import json; print(json.load(open('package.json'))['version'])" 2>/dev/null)
		# Check if node exists locally, use it to check version of package.json
		else if type -q node
			set package_version (node -p "require('./package.json').version" 2>/dev/null)
		end
	end

	# Check if Cargo.toml exists and cargo command exists
	# and use cargo pkgid to figure out the package
	if type -q cargo; and test -f ./Cargo.toml
		# Handle missing field `version` in Cargo.toml.
		# `cargo pkgid` needs Cargo.lock to exists too. If
		# it doesn't, do not show package version
		set -l pkgid (cargo pkgid 2>&1)
		# Early return on error
		echo $pkgid | grep -q "error:"; and return

		# Example input: abc#1.0.0. Example output: 1.0.1
		set package_version (string match -r '#(.*)' $pkgid)[2]
	end

	if test -z "$package_version"
		set package_version ⚠
	else
		set package_version "v$package_version"
	end

	__sf_lib_section \
		$SPACEFISH_PACKAGE_COLOR \
		$SPACEFISH_PACKAGE_PREFIX \
		"$SPACEFISH_PACKAGE_SYMBOL$package_version" \
		$SPACEFISH_PACKAGE_SUFFIX
end
