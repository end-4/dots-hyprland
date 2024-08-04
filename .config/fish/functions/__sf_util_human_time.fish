#
# Human time
#

function __sf_util_human_time -d "Humanize a time interval for display"
	command awk '
		function hmTime(time,   stamp) {
			split("h:m:s:ms", units, ":")
			for (i = 2; i >= -1; i--) {
				if (t = int( i < 0 ? time % 1000 : time / (60 ^ i * 1000) % 60 )) {
					stamp = stamp t units[sqrt((i - 2) ^ 2) + 1] " "
				}
			}
			if (stamp ~ /^ *$/) {
				return "0ms"
			}
			return substr(stamp, 1, length(stamp) - 1)
		}
		{
			print hmTime($0)
		}
	'
end
