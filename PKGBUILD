# Maintainer: Your Name <youremail@domain.com>
pkgname=pacUnclutter-git
pkgver=r5.604f315
pkgrel=1
pkgdesc=""
arch=(any)
url="https://github.com/moormaster/pacUnclutter"
license=('GPL')
depends=(dialog ncurses)
makedepends=('git')
source=('git+https://github.com/moormaster/pacUnclutter')
md5sums=('SKIP')

pkgver() {
	cd "$srcdir/${pkgname%-git}"

	# Git, no tags available
	printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
	cd "$srcdir/${pkgname%-git}"
	install -d -m 755 "$pkgdir/usr/bin"
	cp pacUnclutter.sh "$pkgdir/usr/bin/"
}
