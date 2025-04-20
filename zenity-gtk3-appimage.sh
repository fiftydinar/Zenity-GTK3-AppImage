#!/bin/sh

set -eu

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1

REPO="https://gitlab.gnome.org/GNOME/zenity.git"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
LIB4BIN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
ADWGTK3_VER="$(basename $(curl -Ls -o /dev/null -w %{url_effective} https://github.com/lassekongo83/adw-gtk3/releases/latest))"
ADWGTK3="https://github.com/lassekongo83/adw-gtk3/releases/download/$ADWGTK3_VER/adw-gtk3$ADWGTK3_VER.tar.xz"

# Prepare AppDir
mkdir -p ./AppDir
cd ./AppDir

cat >> ./AppRun << 'EOF'
#!/bin/sh
if command -v gsettings &> /dev/null; then
  if [ "$(gsettings get org.gnome.desktop.interface color-scheme)" = "'prefer-dark'" ]; then
    export GTK_THEME=adw-gtk3-dark
  else
    export GTK_THEME=adw-gtk3
  fi
elif command -v dconf &> /dev/null; then
  if [ "$(dconf read /org/gnome/desktop/interface/color-scheme)" = "'prefer-dark'" ]; then
    export GTK_THEME=adw-gtk3-dark
  else
    export GTK_THEME=adw-gtk3
  fi
else
  export GTK_THEME=adw-gtk3
fi

CURRENTDIR="$(dirname "$(readlink -f "$0")")"
exec "$CURRENTDIR/bin/zenity" "$@"
EOF

chmod +x ./AppRun

git clone "$REPO" ./zenity && (
	cd ./zenity
	git checkout "zenity-3-44"
	meson setup build  --prefix=/usr
	meson compile -C build
	DESTDIR=../../ meson install --no-rebuild -C build
)

mv ./usr/share ./
mv ./usr ./shared
rm -rf ./zenity ./share/help

# zenity is hardcoded to look for files in /usr/share
# we will fix it with binary patching
sed -i 's|/usr/share|././/share|g' ./shared/bin/zenity
echo 'SHARUN_WORKING_DIR=${SHARUN_DIR}' > ./.env

# bundle theming, to make it look like GTK4 with dark theming support
# (no smooth theme transition after theme change when zenity is opened though)
wget "$ADWGTK3" -O $PWD/adw-gtk3-theme.tar.xz
mkdir -p $PWD/usr/share/themes/
tar -xf $PWD/adw-gtk3-theme.tar.xz -C $PWD/usr/share/themes/
rm $PWD/adw-gtk3-theme.tar.xz

# bundle dependencies
wget "$LIB4BIN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -s -k -e \
	./shared/bin/zenity -- --question --text "English or Spanish?"
./lib4bin -p -v -s -k \
	/usr/lib/gdk-pixbuf-*/*/*/* \
	/usr/lib/gio/modules/libgvfsdbus*

./sharun -g

echo '[Desktop Entry]
Name=Zenity
Comment=Display dialog boxes from the command line
Exec=zenity
Terminal=false
Type=Application
NoDisplay=true
StartupNotify=true
Categories=Utility
Icon=zenity' > ./zenity.desktop
touch ./zenity.png

export VERSION="$(xvfb-run -a -- ./AppRun --version)"
echo "$VERSION" > ~/version

# MAKE APPIAMGE WITH FUSE3 COMPATIBLE APPIMAGETOOL
cd ..
wget "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool -n -u "$UPINFO" \
	"$PWD"/AppDir "$PWD"/zenity-"$VERSION"-anylinux-"$ARCH".AppImage

wget -qO ./pelf "https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH"
chmod +x ./pelf
echo "Generating [dwfs]AppBundle...(Go runtime)"
./pelf --add-appdir ./AppDir \
	--appbundle-id="zenity-${VERSION}" \
	--output-to "zenity-${VERSION}-anylinux-${ARCH}.sqfs.AppBundle"

echo "All Done!"
