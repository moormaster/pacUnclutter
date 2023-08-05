# Maintainer: Your Name <youremail@domain.com>
pkgname=pacunclutter-git
pkgver=VERSION
pkgrel=1
pkgdesc=""
arch=(any)
url="https://github.com/moormaster/pacUnclutter"
license=('GPL')
depends=(dialog ncurses)
makedepends=('git')
replaces=("pacUnclutter-git")
conflicts=("pacUnclutter-git")
source=('git+https://github.com/moormaster/pacUnclutter')
md5sums=('SKIP')

pkgver() {
	cd "$srcdir/pacUnclutter"

	# Git, no tags available
	printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

package() {
	cd "$srcdir/pacUnclutter"
	install -d -m 755 "$pkgdir/usr/bin"
	cp pacUnclutter.sh "$pkgdir/usr/bin/"
}
