# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Illogical Impulse GTK/Qt Dependencies"
HOMEPAGE=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"
RESTRICT="strip"

DEPEND=""
RDEPEND="
	kde-apps/kdialog
	dev-qt/qt5compat
	dev-qt/qtbase
	dev-qt/qtdeclarative
	dev-qt/qtimageformats
	dev-qt/qtmultimedia
	dev-qt/qtpositioning
	dev-qt/qtquicktimeline
	dev-qt/qtsensors
	dev-qt/qtsvg
	dev-qt/qttools
	dev-qt/qttranslations
	dev-qt/qtvirtualkeyboard
	dev-qt/qtwayland
	kde-frameworks/syntax-highlighting
	sys-power/upower
	gui-apps/wtype
	x11-misc/ydotool
"
