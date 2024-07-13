#
# Battery
#

function __sf_section_battery -d "Displays battery symbol and charge"
	# ------------------------------------------------------------------------------
	# Configuration
	# ------------------------------------------------------------------------------

	# ------------------------------------------------------------------------------
	# | SPACEFISH_BATTERY_SHOW | below threshold | above threshold | fully charged |
	# |------------------------+-----------------+-----------------+---------------|
	# | false                  | hidden          | hidden          | hidden        |
	# | always                 | shown           | shown           | shown         |
	# | true                   | shown           | hidden          | hidden        |
	# | charged                | shown           | hidden          | shown         |
	# ------------------------------------------------------------------------------

	__sf_util_set_default SPACEFISH_BATTERY_SHOW true
	__sf_util_set_default SPACEFISH_BATTERY_PREFIX ""
	__sf_util_set_default SPACEFISH_BATTERY_SUFFIX " "
	__sf_util_set_default SPACEFISH_BATTERY_SYMBOL_CHARGING ⇡
	__sf_util_set_default SPACEFISH_BATTERY_SYMBOL_DISCHARGING ⇣
	__sf_util_set_default SPACEFISH_BATTERY_SYMBOL_FULL •
	__sf_util_set_default SPACEFISH_BATTERY_THRESHOLD 10

	# ------------------------------------------------------------------------------
	# Section
	# ------------------------------------------------------------------------------

	# Show section only if any of the following is true
	# - SPACEFISH_BATTERY_SHOW = "always"
	# - SPACEFISH_BATTERY_SHOW = "true" and
	#	- battery percentage is below the given limit (default: 10%)
	# - SPACEFISH_BATTERY_SHOW = "charged" and
	#	- Battery is fully charged

	# Check that user wants to show battery levels
	[ $SPACEFISH_BATTERY_SHOW = false ]; and return

	set -l battery_data
	set -l battery_percent
	set -l battery_status
	set -l battery_color
	set -l battery_symbol

	# Darwin and macOS machines
	if type -q pmset
		set battery_data (pmset -g batt | grep "InternalBattery")

		# Return if no internal battery
		if test -z (echo $battery_data)
			return
		end

		set battery_percent (echo $battery_data | grep -oE "[0-9]{1,3}%")
		# spaceship has echo $battery_data | awk -F '; *' 'NR==2 { print $2 }', but NR==2 did not return anything.
		set battery_status (echo $battery_data | awk -F '; *' '{ print $2 }')

	# Linux machines
	else if type -q upower
		set -l battery (upower -e | grep battery | head -1)

		[ -z $battery ]; and return

		set -l IFS # Clear IFS to allow for multi-line variables
		set battery_data (upower -i $battery)
		set battery_percent (echo $battery_data | grep percentage | awk '{print $2}')
		set battery_status (echo $battery_data | grep state | awk '{print $2}')

	# Windows machines.
	else if type -q acpi
		set -l battery_data (acpi -b 2>/dev/null | head -1)

		# Return if no battery
		[ -z $battery_data ]; and return

		set battery_percent ( echo $battery_data | awk '{print $4}' )
		set battery_status ( echo $battery_data | awk '{print tolower($3)}' )
	else
		return
	end

	 # Remove trailing % and symbols for comparison
	set battery_percent (echo $battery_percent | string trim --chars=%[,;])

	if test "$battery_percent" -eq 100 -o -n (echo (string match -r "(charged|full)" $battery_status))
		set battery_color green
	else if test "$battery_percent" -lt "$SPACEFISH_BATTERY_THRESHOLD"
		set battery_color red
	else
		set battery_color yellow
	end

	# Battery indicator based on current status of battery
	if test "$battery_status" = "charging"
		set battery_symbol $SPACEFISH_BATTERY_SYMBOL_CHARGING
	else if test -n (echo (string match -r "^[dD]ischarg.*" $battery_status))
		set battery_symbol $SPACEFISH_BATTERY_SYMBOL_DISCHARGING
	else
		set battery_symbol $SPACEFISH_BATTERY_SYMBOL_FULL
	end

	if test "$SPACEFISH_BATTERY_SHOW" = "always" \
	-o "$battery_percent" -lt "$SPACEFISH_BATTERY_THRESHOLD" \
	-o "$SPACEFISH_BATTERY_SHOW" = "charged" \
	-a -n (echo (string match -r "(charged|full)" $battery_status))
		__sf_lib_section \
			$battery_color \
			$SPACEFISH_BATTERY_PREFIX \
			"$battery_symbol$battery_percent%" \
			$SPACEFISH_BATTERY_SUFFIX
	end
end
