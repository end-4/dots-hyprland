pkgname=illogical-impulse-microtex-git
_pkgname=MicroTeX
pkgver=r492.d87ebec
pkgrel=1
pkgdesc='MicroTeX for illogical-impulse dotfiles.'
#pkgdesc="A dynamic, cross-platform, and embeddable LaTeX rendering library"
arch=("x86_64")
url="https://github.com/NanoMichael/${_pkgname}"
license=('MIT')
depends=(
	tinyxml2
	gtkmm3
	gtksourceviewmm
	cairomm
)
makedepends=("git" "cmake")
source=("git+${url}.git")
sha256sums=("SKIP")

pkgver() {
  cd $_pkgname
  printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

build() {
  cd $_pkgname
  cmake -B build -S . -DCMAKE_BUILD_TYPE=None
  cmake --build build
}

package() {
  cd $_pkgname
  install -Dm0755 -t "$pkgdir/opt/$_pkgname/" build/LaTeX
  cp -r build/res "$pkgdir/opt/$_pkgname/"
  install -Dm0644 -t "$pkgdir/usr/share/licenses/$pkgname/" LICENSE
}
