printf "${STY_YELLOW}"
printf "============WARNING/NOTE (1)============\n"
printf "Ensure you have a global use flag for elogind or systemd in your make.conf for simplicity\n"
printf "Or you can manually add the use flags for each package that requires it\n"
printf "${STY_RST}"
pause

printf "${STY_YELLOW}"
printf "============WARNING/NOTE (2)============\n"
printf "https://github.com/end-4/dots-hyprland/blob/main/sdata/dist-gentoo/README.md\n"
printf "Checkout the above README for potential bug fixes or additional information\n\n"
printf "${STY_RST}"
pause

x sudo emerge --update --quiet app-eselect/eselect-repository
x sudo emerge --update --quiet net-misc/rsync
x sudo emerge --update --quiet app-portage/smart-live-rebuild

if [[ -z $(eselect repository list | grep -E ".*guru \*.*") ]]; then
  v sudo eselect repository enable guru
fi

if [[ -z $(eselect repository list | grep -E ".*hyproverlay \*.*") ]]; then
	v sudo eselect repository enable hyproverlay
fi

overlay_dst="/var/db/repos/ii-dots"

x sudo mkdir -p "${overlay_dst}"
x sudo mkdir -p /etc/portage/repos.conf

v sudo rsync -a --delete --chown=root:root "./sdata/dist-gentoo/overlay/" "${overlay_dst}/"
v sudo cp "./sdata/dist-gentoo/ii-dots.conf" "/etc/portage/repos.conf/ii-dots.conf"

arch=$(portageq envvar ACCEPT_KEYWORDS)

v sh -c "sed 's/$/ ~${arch}/' ./sdata/dist-gentoo/keywords |
    sudo tee /etc/portage/package.accept_keywords/illogical-impulse >/dev/null"

v sudo cp "./sdata/dist-gentoo/useflags" "/etc/portage/package.use/illogical-impulse"
v sudo sh -c 'cat ./sdata/dist-gentoo/additional-useflags >> /etc/portage/package.use/illogical-impulse'

v sudo emerge --sync
v sudo emerge --quiet --newuse --update --deep @world
v sudo emerge --quiet @smart-live-rebuild

x source ./sdata/dist-gentoo/metapkgs.sh

for pkg in "${metapkgs[@]}"; do
  v sudo emerge --update --quiet "${pkg}"
done

x sudo emerge --update --quiet dev-lang/python:3.12
