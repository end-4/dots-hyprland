# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse Audio Dependencies"
HOMEPAGE="https://github.com/end-4/dots-hyprland"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

RDEPEND="
	media-sound/cava
	media-sound/pavucontrol-qt
	media-video/wireplumber
	media-video/pipewire[sound-server]
	dev-libs/libdbusmenu[gtk3]
	media-sound/playerctl
"
