# Copyright 2023-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="Hyprland QT/qml utility apps"
HOMEPAGE="https://github.com/hyprwm/hyprland-qtutils"
EGIT_REPO_URI="https://github.com/hyprwm/hyprland-qtutils.git"

LICENSE="BSD"

SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

RDEPEND="
	dev-qt/qtbase:6
	dev-qt/qtdeclarative:6
	dev-qt/qtwayland:6
	gui-libs/hyprutils:=
	gui-libs/hyprland-qt-support
	kde-frameworks/qqc2-desktop-style:6
"

DEPEND="${RDEPEND}"
