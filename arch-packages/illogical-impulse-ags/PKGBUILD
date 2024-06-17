# Modified from AUR package "aylurs-gtk-shell-git" maintained by kotontrion <kotontrion@tutanota.de>
pkgname=illogical-impulse-ags
_pkgname=ags
pkgver=r525.05e0f23
pkgrel=1
pkgdesc="Aylurs's Gtk Shell (AGS), version fixed for illogical-impulse dotfiles."
arch=('x86_64')
url="https://github.com/Aylur/ags"
license=('GPL3')
makedepends=('git' 'gobject-introspection' 'meson' 'npm' 'typescript')
depends=('gjs' 'glib2' 'glib2-devel' 'glibc' 'gtk3' 'gtk-layer-shell' 'libpulse' 'pam')
optdepends=('gnome-bluetooth-3.0: required for bluetooth service'
            'greetd: required for greetd service'
            'libdbusmenu-gtk3: required for systemtray service'
            'libsoup3: required for the Utils.fetch feature'
            'libnotify: required for sending notifications'
            'networkmanager: required for network service'
            'power-profiles-daemon: required for powerprofiles service'
            'upower: required for battery service')
conflicts=('aylurs-gtk-shell' 'aylurs-gtk-shell-git')
backup=('etc/pam.d/ags')
source=("git+${url}.git#commit=05e0f23534fa30c1db2a142664ee8f71e38db260"
        "git+https://gitlab.gnome.org/GNOME/libgnome-volume-control")
sha256sums=('SKIP'
            'SKIP')

pkgver(){
  cd $srcdir/$_pkgname
  printf 'r%s.%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

prepare() {
  cd $srcdir/$_pkgname
  git submodule init
  git config submodule.subprojects/gvc.url "$srcdir/libgnome-volume-control"
  git -c protocol.file.allow=always submodule update
}

build() {
  cd $srcdir/$_pkgname
  npm install
  arch-meson build --libdir "lib/$_pkgname" -Dbuild_types=true
  meson compile -C build
}

package() {
  cd $srcdir/$_pkgname
  meson install -C build --destdir "$pkgdir"
  ln -sf /usr/share/com.github.Aylur.ags/com.github.Aylur.ags ${pkgdir}/usr/bin/ags
}
