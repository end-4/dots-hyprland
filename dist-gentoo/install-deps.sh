printf "${STY_YELLOW}"
printf "============WARNING/NOTE============\n"
printf "GCC in use: $(which gcc)\n"
printf "GCC version info: $(gcc --version | grep gcc)\n"
printf "GCC version number: $(gcc --version | grep gcc | awk '{print $3}')\n"
printf "GCC-15>= is required for Hyprland\n"
printf "If you have GCC-15>= and it's currently set then you can safely ignore this\n"
printf "If not, you must ensure you are using the correct GCC version and set it (gcc-config <number>), then emerge re-emerge @world with an empty tree (emerge -e @world)\n"
printf "${STY_RESET}"
pause

if [[ -z $(eselect repository list | grep localrepo) ]]; then
	v sudo eselect repository create localrepo
	v sudo eselect repository enable localrepo 
fi

if [[ -z $(eselect repository list | grep guru) ]]; then
	v sudo eselect repository enable guru
fi

arch=$(portageq envvar ACCEPT_KEYWORDS)

# Exclude hyprland, will deal with that separately
metapkgs=(illogical-impulse-{audio,backlight,basic,bibata-modern-classic-bin,fonts-themes,hyprland,kde,microtex-git,oneui4-icons-git,portal,python,screencapture,toolkit,widgets})

ebuild_dir="/var/db/repos/localrepo"

# Unmasks
x cp ./dist-gentoo/keywords ./dist-gentoo/keywords-user
x sed -i "s/$/ ~${arch}/" ./dist-gentoo/keywords-user
v sudo cp ./dist-gentoo/keywords-user /etc/portage/package.accept_keywords/illogical-impulse

# Use Flags
v sudo cp ./dist-gentoo/useflags /etc/portage/package.use/illogical-impulse

# Update system
v sudo emerge --sync
v sudo emerge --ask --verbose --newuse --update --deep @world
v sudo emerge --depclean

# Remove old ebuilds (if this isn't done the wildcard will fuck upon a version change)
x sudo rm -fr ${ebuild_dir}/app-misc/illogical-impulse-*

###### LIVE EBUILDS START
HYPR_DIR="illogical-impulse-hyprland"
x sudo mkdir -p ${ebuild_dir}/dev-libs/hyprgraphics/
x sudo mkdir -p ${ebuild_dir}/gui-libs/hyprland-qt-support
x sudo mkdir -p ${ebuild_dir}/gui-libs/hyprland-qtutils
x sudo mkdir -p ${ebuild_dir}/dev-libs/hyprlang
x sudo mkdir -p ${ebuild_dir}/dev-libs/hyprlang
x sudo mkdir -p ${ebuild_dir}/dev-util/hyprwayland-scanner

v sudo cp ./dist-gentoo/${HYPR_DIR}/hyprgraphics*.ebuild ${ebuild_dir}/dev-libs/hyprgraphics
v sudo cp ./dist-gentoo/${HYPR_DIR}/hyprland-qt-support*.ebuild ${ebuild_dir}/gui-libs/hyprland-qt-support
v sudo cp ./dist-gentoo/${HYPR_DIR}/hyprland-qtutils*.ebuild ${ebuild_dir}/gui-libs/hyprland-qtutils
v sudo cp ./dist-gentoo/${HYPR_DIR}/hyprlang*.ebuild ${ebuild_dir}/dev-libs/hyprlang
v sudo cp ./dist-gentoo/${HYPR_DIR}/hyprwayland-scanner*.ebuild ${ebuild_dir}/dev-util/hyprwayland-scanner

v sudo ebuild ${ebuild_dir}/dev-libs/hyprgraphics/hyprgraphics*9999.ebuild digest
v sudo ebuild ${ebuild_dir}/gui-libs/hyprland-qt-support/hyprland-qt-support*9999.ebuild digest
v sudo ebuild ${ebuild_dir}/gui-libs/hyprland-qtutils/hyprland-qtutils*9999.ebuild digest
v sudo ebuild ${ebuild_dir}/dev-libs/hyprlang/hyprlang*9999.ebuild digest
v sudo ebuild ${ebuild_dir}/dev-util/hyprwayland-scanner/hyprwayland-scanner*9999.ebuild digest
###### LIVE EBUILDS END


# Install dependencies
for i in "${metapkgs[@]}"; do
	x sudo mkdir -p ${ebuild_dir}/app-misc/${i}
	v sudo cp ./dist-gentoo/${i}/${i}*.ebuild ${ebuild_dir}/app-misc/${i}/
	v sudo ebuild ${ebuild_dir}/app-misc/${i}/*.ebuild digest
	v sudo emerge --quiet app-misc/${i}
done


