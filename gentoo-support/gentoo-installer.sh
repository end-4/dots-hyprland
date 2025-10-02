#!/bin/bash

latest_gcc_ver=15
ebuild_name="end4-1.0.ebuild"
arch=$(portageq envvar ACCEPT_KEYWORDS)

print_message () {
	message=$1
	color=$2
	if [[ ${color} = "r" ]]; then
		echo -e "\033[31m$message\033[0m"	
	elif [[ ${color} = "g" ]]; then
		echo -e "\033[32m$message\033[0m"	
	else
		echo -e "\033[34m$message\033[0m"	
	fi
	color="b"
}
get_input () {
	input_message=$1
	answer=""
	bool_answer=-1
	while true; do
		read -p "$(print_message "$input_message ([\033[32mY\033[34m]/\033[31mn\033[0m): ")" answer
		case "$answer" in
		[Yy]* | "" ) 
			bool_answer=0
			break
			;;
		[Nn]* )
			bool_answer=1
			break
			;;
		* )
            		echo -e "\033[31mInput not understood ([\033[32mY\033[34m]/\033[31mn\033[0m)\033[0m)"
			;;
		esac
	done
}

exec_cmd () {
	cmd=$1
	message=$2
	terminate=$3
	get_input "$message"
	case "$bool_answer" in
	0 )
		print_message "+ ${cmd}" "g"
		[ ! -z "$cmd" ] && eval "$cmd"
		;;
	1 )
		print_message "- ${cmd}" "r"
		[ "$terminate" == "y" ] && exit 1
		;;
	* )
		exit 1
		;;
	esac
	cmd=""
}

print_message "If you want to use the latest Hyprland version, you must unmask it first, the script does not do this. Change GCC version to a compatible one and then emerge @world."
echo ""
print_message "ARCHITECTURE DETECTED IS \033[32m$arch\033[0m"

exec_cmd "sudo eselect repository create localrepo || true" "Create local repository (ignore errors)"
exec_cmd "sudo eselect repository enable localrepo || true" "Enable local repository (ignore errors)"

exec_cmd "sudo mkdir -p /var/db/repos/localrepo/app-misc/end4 || true" "Create directory for the eBuild"
exec_cmd "sudo cp end4-1.0.ebuild /var/db/repos/localrepo/app-misc/end4" "Import the eBuild"
exec_cmd "sudo ebuild /var/db/repos/localrepo/app-misc/end4/${ebuild_name} digest" "Digest the eBuild"

exec_cmd "sudo cp end4-unmasks /etc/portage/package.accept_keywords/end4 && sudo sed -i 's/$/ ~${arch}/' /etc/portage/package.accept_keywords/end4" "Import basic unmasks"

exec_cmd "sudo cp end4-recommended-use-flags /etc/portage/package.use/end4" "Import recommended use flags"

exec_cmd "sudo emerge --sync" "Sync portage"
exec_cmd "sudo emerge --ask --verbose --update --deep --newuse @world" "Update @world"
exec_cmd "sudo emerge --depclean" "Clean dependencies"

exec_cmd "sudo emerge -q app-misc/end4" "Emerge end4 dot-files"
exec_cmd "cp -r ../.config/* ~/.config" "Copy config files over"




