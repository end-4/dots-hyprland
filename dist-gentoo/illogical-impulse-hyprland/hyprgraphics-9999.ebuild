# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="Hyprland graphics / resource utilities (live/HEAD)"
HOMEPAGE="https://github.com/hyprwm/hyprgraphics"

# For live ebuilds, Portage clones the git repo
EGIT_REPO_URI="https://github.com/hyprwm/hyprgraphics.git"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=gui-libs/hyprutils-0.1.1:=
	media-libs/libjpeg-turbo:=
	media-libs/libjxl:=
	media-libs/libspng
	media-libs/libwebp:=
	sys-apps/file
	x11-libs/cairo
"
DEPEND="${RDEPEND}"

