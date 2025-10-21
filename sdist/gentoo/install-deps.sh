printf "${STY_YELLOW}"
printf "============WARNING/NOTE (1)============\n"
printf "GCC in use: $(which gcc)\n"
printf "GCC version info: $(gcc --version | grep gcc)\n"
printf "GCC version number: $(gcc --version | grep gcc | awk '{print $3}')\n"
printf "GCC-15>= is required for Hyprland\n"
printf "If you have GCC-15>= and it's currently set then you can safely ignore this\n"
printf "If not, you must ensure you are using the correct GCC version and set it (gcc-config <number>)\n"
printf "It is heavily recommended to re-emerge @world with an empty tree after changing GCC version (emerge -e @world)\n\n"
printf "${STY_RST}"
pause

printf "${STY_YELLOW}"
printf "============WARNING/NOTE (2)============\n"
printf "Ensure you have a global use flag for elogind or systemd in your make.conf for simplicity\n"
printf "Or you can manually add the use flags for each package that requires it\n"
printf "${STY_RST}"
pause

printf "${STY_YELLOW}"
printf "https://github.com/end-4/dots-hyprland/blob/main/sdist/gentoo/README.md"
printf "Checkout the above README for potential bug fixes or additional information"
printf "${STY_RST}"
pause

x sudo emerge --noreplace --quiet app-eselect/eselect-repository

if [[ -z $(eselect repository list | grep localrepo) ]]; then
	v sudo eselect repository create localrepo
	v sudo eselect repository enable localrepo 
fi

if [[ -z $(eselect repository list | grep -E ".*guru \*.*") ]]; then
        v sudo eselect repository enable guru
fi

arch=$(portageq envvar ACCEPT_KEYWORDS)

# Exclude hyprland, will deal with that separately
metapkgs=(illogical-impulse-{audio,backlight,basic,bibata-modern-classic-bin,fonts-themes,hyprland,kde,microtex-git,oneui4-icons-git,portal,python,quickshell-git,screencapture,toolkit,widgets})

ebuild_dir="/var/db/repos/localrepo"

# Unmasks
x sudo cp ./sdist/gentoo/keywords ./sdist/gentoo/keywords-user
x sed -i "s/$/ ~${arch}/" ./sdist/gentoo/keywords-user
v sudo cp ./sdist/gentoo/keywords-user /etc/portage/package.accept_keywords/illogical-impulse

# Use Flags
v sudo cp ./sdist/gentoo/useflags /etc/portage/package.use/illogical-impulse
v sudo sh -c 'cat ./sdist/gentoo/additional-useflags >> /etc/portage/package.use/illogical-impulse'

# Update system
v sudo emerge --sync
v sudo emerge --quiet --newuse --update --deep @world
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

v sudo cp ./sdist/gentoo/${HYPR_DIR}/hyprgraphics*.ebuild ${ebuild_dir}/dev-libs/hyprgraphics
v sudo cp ./sdist/gentoo/${HYPR_DIR}/hyprland-qt-support*.ebuild ${ebuild_dir}/gui-libs/hyprland-qt-support
v sudo cp ./sdist/gentoo/${HYPR_DIR}/hyprland-qtutils*.ebuild ${ebuild_dir}/gui-libs/hyprland-qtutils
v sudo cp ./sdist/gentoo/${HYPR_DIR}/hyprlang*.ebuild ${ebuild_dir}/dev-libs/hyprlang
v sudo cp ./sdist/gentoo/${HYPR_DIR}/hyprwayland-scanner*.ebuild ${ebuild_dir}/dev-util/hyprwayland-scanner

v sudo ebuild ${ebuild_dir}/dev-libs/hyprgraphics/hyprgraphics*9999.ebuild digest
v sudo ebuild ${ebuild_dir}/gui-libs/hyprland-qt-support/hyprland-qt-support*9999.ebuild digest
v sudo ebuild ${ebuild_dir}/gui-libs/hyprland-qtutils/hyprland-qtutils*9999.ebuild digest
v sudo ebuild ${ebuild_dir}/dev-libs/hyprlang/hyprlang*9999.ebuild digest
v sudo ebuild ${ebuild_dir}/dev-util/hyprwayland-scanner/hyprwayland-scanner*9999.ebuild digest
###### LIVE EBUILDS END


# Install dependencies
for i in "${metapkgs[@]}"; do
	x sudo mkdir -p ${ebuild_dir}/app-misc/${i}
	v sudo cp ./sdist/gentoo/${i}/${i}*.ebuild ${ebuild_dir}/app-misc/${i}/
	v sudo ebuild ${ebuild_dir}/app-misc/${i}/*.ebuild digest
	v sudo emerge --quiet app-misc/${i}
done

# Currently using 3.12 python, this doesn't need to be default though
v sudo emerge --noreplace --quiet dev-lang/python:3.12
