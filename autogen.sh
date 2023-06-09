#!/bin/sh
# Run this to generate all the initial makefiles, etc.

test -n "$srcdir" || srcdir=$(dirname "$0")
test -n "$srcdir" || srcdir=.

olddir=$(pwd)
cd "$srcdir"

if ! command -v autoreconf >/dev/null; then
    echo "*** No autoreconf found, please install it ***"
    exit 1
fi

# INSTALL are required by automake, but may be deleted by clean
# up rules. to get automake to work, simply touch these here, they will be
# regenerated from their corresponding *.in files by ./configure anyway.
touch INSTALL

if ! test -f subprojects/libglnx/README.md -a -f subprojects/bubblewrap/README.md -a -f subprojects/dbus-proxy/README.md; then
    git submodule update --init
fi
# Workaround automake bug with subdir-objects and computed paths
sed -e 's,$(libglnx_srcpath),subprojects/libglnx,g' < subprojects/libglnx/Makefile-libglnx.am > subprojects/Makefile-libglnx.am.inc
sed -e 's,$(bwrap_srcpath),subprojects/bubblewrap,g' < subprojects/bubblewrap/Makefile-bwrap.am > subprojects/Makefile-bwrap.am.inc

if ! command -v gtkdocize >/dev/null; then
    echo "*** You don't have gtk-doc installed, and thus won't be able to generate the documentation. ***"
    rm -f gtk-doc.make
    cat > gtk-doc.make <<EOF
EXTRA_DIST =
CLEANFILES =
EOF
else
    # gtkdocize needs the macro directory to exist before
    # we call autoreconf
    mkdir -p m4
    gtkdocize || exit $?
fi

autoreconf --force --install --verbose || exit $?

cd "$olddir"
test -n "$NOCONFIGURE" || "$srcdir/configure" "$@"
