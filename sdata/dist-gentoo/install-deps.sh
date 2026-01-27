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
x sudo emerge --update --quiet app-portage/smart-live-rebuild
# Currently using 3.12 python, this doesn't need to be default though
x sudo emerge --update --quiet dev-lang/python:3.12

if [[ -z $(eselect repository list | grep ii-dots) ]]; then
	v sudo eselect repository create ii-dots
	v sudo eselect repository enable ii-dots
fi

if [[ -z $(eselect repository list | grep -E ".*guru \*.*") ]]; then
        v sudo eselect repository enable guru
fi

if [[ -z $(eselect repository list | grep -E ".*hyproverlay \*.*") ]]; then
	v sudo eselect repository enable hyproverlay
fi

arch=$(portageq envvar ACCEPT_KEYWORDS)

# Exclude hyprland, will deal with that separately
metapkgs=(illogical-impulse-{audio,backlight,basic,bibata-modern-classic-bin,fonts-themes,hyprland,kde,microtex-git,oneui4-icons-git,portal,python,quickshell-git,screencapture,toolkit,widgets})

ebuild_dir="/var/db/repos/ii-dots"


########## IMPORT KEYWORDS (START)
# Illogical-Impulse
x sudo cp ./sdata/dist-gentoo/keywords ./sdata/dist-gentoo/keywords-user
x sed -i "s/$/ ~${arch}/" ./sdata/dist-gentoo/keywords-user
v sudo cp ./sdata/dist-gentoo/keywords-user /etc/portage/package.accept_keywords/illogical-impulse

########## IMPORT USEFLAGS
v sudo cp ./sdata/dist-gentoo/useflags /etc/portage/package.use/illogical-impulse
v sudo sh -c 'cat ./sdata/dist-gentoo/additional-useflags >> /etc/portage/package.use/illogical-impulse'

########## UPDATE SYSTEM
v sudo emerge --sync
v sudo emerge --quiet --newuse --update --deep @world
v sudo emerge --quiet @smart-live-rebuild
v sudo emerge --depclean

# Hard coded for now
v sudo emerge --update --quiet '>=dev-cpp/glaze-6.1.0'
v sudo emerge --update --quiet dev-libs/pugixml

# Remove old ebuilds (if this isn't done the wildcard will fuck upon a version change)
x sudo rm -fr ${ebuild_dir}/app-misc/illogical-impulse-*

source ./sdata/dist-gentoo/import-local-pkgs.sh

########## INSTALL ILLOGICAL-IMPUSEL EBUILDS
for i in "${metapkgs[@]}"; do
	x sudo mkdir -p ${ebuild_dir}/app-misc/${i}
	v sudo cp ./sdata/dist-gentoo/${i}/${i}*.ebuild ${ebuild_dir}/app-misc/${i}/
	v sudo ebuild ${ebuild_dir}/app-misc/${i}/*.ebuild digest
	v sudo emerge --update --quiet app-misc/${i}
done
