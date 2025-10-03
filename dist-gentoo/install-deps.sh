if [[ -z $(eselect repository list | grep localrepo) ]]; then
	v sudo eselect repository create localrepo
	v sudo eselect repository enable localrepo 
fi

if [[ -z $(eselect repository list | grep guru) ]]; then
	v sudo eselect repository enable guru
fi

arch=$(portageq envvar ACCEPT_KEYWORDS)

metapkgs=(illogical-impulse-{audio,backlight,basic,bibata-modern-classic-bin,fonts-themes,hyprland,kde,microtex-git,oneui4-icons-git,portal,python,screencapture,toolkit,widgets})

ebuild_dir="/var/db/repos/localrepo/app-misc"

# Unmasks
x cp ./dist-gentoo/keywords ./dist-gentoo/keywords-user
x sed -i "s/$/ ~${arch}/" ./dist-gentoo/keywords-user
v sudo cp ./dist-gentoo/keywords-user /etc/portage/package.accept_keywords/end4

# Use Flags
v sudo cp ./dist-gentoo/useflags /etc/portage/package.use/end4

# Update system
#v sudo emerge --sync
#v sudo emerge --ask --verbose --newuse --update --deep @world
#v sudo emerge --depclean

# Remove old ebuilds (if this isn't done the wildcard will fuck upon a version change)
x sudo rm -r ${ebuild_dir}/illogical-impulse-*

# Install dependencies
to_install=""
for i in "${metapkgs[@]}"; do
	x sudo mkdir -p ${ebuild_dir}/${i}
	v sudo cp ./dist-gentoo/${i}/${i}*.ebuild ${ebuild_dir}/${i}/
	v sudo ebuild ${ebuild_dir}/${i}/*.ebuild digest
	to_install+="app-misc/${i} "
done

# Easier to debug when it's all installed at once
#v sudo emerge --quiet ${to_install}



