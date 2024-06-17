pkgname=illogical-impulse-bibata-modern-classic-bin
pkgver=2.0.6
pkgrel=1
pkgdesc="Material Based Cursor Theme, installed for illogical-impulse dotfiles"
arch=('any')
url="https://github.com/ful1e5/Bibata_Cursor"
license=('GPL-3.0-or-later')
conflicts=("bibata-cursor-theme" "bibata-cursor-theme-bin")
options=('!strip')
_variant=Bibata-Modern-Classic
source=("${pkgname%-bin}-$pkgver.tar.xz::$url/releases/download/v$pkgver/$_variant.tar.xz")
sha256sums=('SKIP')

package() {
  install -dm755 "$pkgdir/usr/share/icons"
  cp -dr --no-preserve=mode $_variant "$pkgdir/usr/share/icons"
}
