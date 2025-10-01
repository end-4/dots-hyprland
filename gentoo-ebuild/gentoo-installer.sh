#!/bin/bash

latest_gcc_ver=15
ebuild_name="end4-1.0.ebuild"
arch=$(portageq envvar ACCEPT_KEYWORDS)

print_message () {
	message=$1
	echo -e "\033[34m$message\033[0m"	
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
		echo -e "\033[32m+\033[2m $cmd\033[0m"
		[ ! -z "$cmd" ] && eval "$cmd"
		;;
	1 )
		echo -e "\033[32m-\033[2m $cmd\033[0m"
		[ "$terminate" == "y" ] && exit 1
		;;
	* )
		exit 1
		;;
	esac
	cmd=""
}

print_message "IF YOU WANT TO USE THE LATESt HYPRlAND VERSION YOU MUSt UNMASK it, CHANGE GCC VERSIONS TO A COMPATIBLE ONE, THEN EMERGE @world IF YOU YOUR CURRENT GCC WASN'T THE SAME."
echo ""
print_message "ARCHITECTURE DETECTED IS \033[32m$arch\033[0m"

exec_cmd "sudo emerge --sync" "Sync portage"
exec_cmd "sudo emerge --ask --verbose --update --deep --newuse @world" "Update @world"
exec_cmd "sudo eselect repository create localrepo || true" "Create local repository"
exec_cmd "sudo eselect repository enable localrepo || true" "Enable local repository"
exec_cmd "sudo mkdir -p /var/db/repos/localrepo/app-misc/end4 || true" "Create directory for the eBuild"
exec_cmd "sudo cp end4-1.0.ebuild /var/db/repos/localrepo/app-misc/end4" "Import the eBuild"
exec_cmd "sudo ebuild /var/db/repos/localrepo/app-misc/end4/${ebuild_name} digest" "Digest the eBuild"
exec_cmd "sudo cp end4-recommended-use-flags /etc/portage/package.use/end4" "Use recommended use flags"





