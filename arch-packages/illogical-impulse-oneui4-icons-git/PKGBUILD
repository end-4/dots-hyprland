pkgname=illogical-impulse-oneui4-icons-git
_pkgname=OneUI4-Icons
pkgver=r64.9ba2190
pkgrel=1
pkgdesc="A fork of mjkim0727/OneUI4-Icons for illogical-impulse dotfiles."
arch=('x86_64')
url="https://github.com/end-4/OneUI4-Icons"
license=('GPL3')
source=("git+${url}.git")
sha256sums=('SKIP')
options=('!strip')

pkgver(){
  cd $srcdir/$_pkgname
  printf 'r%s.%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
  cd $srcdir/$_pkgname
  install -dm755 "$pkgdir/usr/share/icons"
  for _i in OneUI{,-dark,-light}; do
    cp -dr --no-preserve=mode "$_i" "$pkgdir/usr/share/icons/$_i"
  done
}
