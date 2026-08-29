# Maintainer: Esli Silva <esli@esli.io>

pkgname=sysz-ng
pkgver=2.1.0
pkgrel=1
pkgdesc="fzf terminal UI for systemctl (sysz-ng fork)"
arch=("any")
url="https://github.com/Esl1h/sysz-ng"
license=("UNLICENSE")
depends=("bash" "fzf")
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
  install -Dm755 "$srcdir/$pkgname-$pkgver/sysz-ng" "$pkgdir/usr/bin/sysz-ng"
}
