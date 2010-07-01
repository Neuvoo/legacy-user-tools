# Copyright 1999-2010 Neuvoo
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# Auto-generated ebin ebuild: do not edit directly!

## BEGIN ebuild %%P%%
%%EBUILD%%
## END ebuild %%P%%

T_XPAK="${T}/xpak"
XPAK_ENV="${T_XPAK}/environment"
if [ -f "${XPAK_ENV}" ]; then
	"${XPAK_ENV}"
fi

SRC_URI="%%SRC_URI%%"

pkg_setup() {
	%%USE_CHECK%%
}
src_unpack() {
	full_A="${DISTDIR}/${A}"
	mkdir "${T_XPAK}" && cd "${T_XPAK}" || die "Could not create xpak tmp dir"
	echo qtbz2 -x "${full_A}" -O \| qxpak -x -O - environment.bz2 \| bunzip2 \> "${XPAK_ENV}" \|\| die "Could not extract environment"
	qtbz2 -x "${full_A}" -O | qxpak -x -O - environment.bz2 | bunzip2 > "${XPAK_ENV}" || die "Could not extract environment"
}
src_prepare() {
	:
}
src_configure() {
	:
}
src_compile() {
	:
}
src_test() {
	:
}
src_install() {
	full_A="${DISTDIR}/${A}"
	cd "${D}"
	qtbz2 -t "${full_A}" -O | tar -jxf - || die "Could not install xpak"
}
