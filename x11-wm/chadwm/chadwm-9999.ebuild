# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit savedconfig toolchain-funcs

DESCRIPTION="a dynamic window manager for X11"
HOMEPAGE="https://github.com/siduck/chadwm"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/siduck/chadwm.git"
fi

LICENSE="MIT"
SLOT="0"
IUSE="savedconfig xinerama"

RDEPEND="
	media-libs/fontconfig
	x11-libs/libX11
	>=x11-libs/libXft-2.3.5
	xinerama? ( x11-libs/libXinerama )
"
DEPEND="
	${RDEPEND}
	x11-base/xorg-proto
	xinerama? ( x11-base/xorg-proto )
"

src_prepare() {
	default

	cd chadwm || die "Verzeichniswechsel nach chadwm fehlgeschlagen"

	sed -i \
		-e "s/ -Os / /" \
		-e "/^\(LDFLAGS\|CFLAGS\|CPPFLAGS\)/{s| = | += |g;s|-s ||g}" \
		-e "/^X11LIB/{s:/usr/X11R6/lib:/usr/$(get_libdir)/X11:}" \
		-e '/^X11INC/{s:/usr/X11R6/include:/usr/include/X11:}' \
		config.mk || die

}

src_configure() {
    cd chadwm || die "Verzeichniswechsel nach chadwm fehlgeschlagen"
    if use savedconfig; then
        echo ">>> [DEBUG] Using savedconfig: Restoring config.def.h"
        restore_config config.def.h
        cp config.def.h config.h || die "Kopieren von config.def.h nach config.h fehlgeschlagen"
    else
        echo ">>> [DEBUG] NOT using savedconfig, using default config.def.h"
    fi
}

src_compile() {
	cd chadwm || die "Verzeichniswechsel nach chadwm fehlgeschlagen"
	if use xinerama; then
		emake CC="$(tc-getCC)" dwm
	else
		emake CC="$(tc-getCC)" XINERAMAFLAGS="" XINERAMALIBS="" dwm
	fi
}

src_install() {
	cd chadwm || die "Verzeichniswechsel nach chadwm fehlgeschlagen"
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install

	exeinto /etc/X11/Sessions
	newexe "${FILESDIR}"/dwm-session2 dwm

	insinto /usr/share/xsessions
	doins "${FILESDIR}"/dwm.desktop

	dodoc ../README.md

	use savedconfig && save_config config.def.h
}
