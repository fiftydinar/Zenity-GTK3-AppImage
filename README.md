# Zenity-adw-gtk3-AppImage
Unofficial AppImage of Zenity **GTK3 Version** with bundled `adw-gtk3` theme

**raison d'être:** 

![Gnome moment](https://github.com/Samueru-sama/Zenity-GTK3-AppImage/assets/36420837/3e5586a2-f21d-4e96-89c9-3becc1642fdc)

---------------------------------------------------------------

AppImage made using [sharun](https://github.com/VHSgunzo/sharun), which makes it extremely easy to turn any binary into a portable package without using containers or similar tricks.

**This AppImage bundles everything and should work on any linux distro, even on musl based ones.**

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -i zenity` or `appman -i zenity`

* [dbin](https://github.com/xplshn/dbin) `dbin install zenity.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install zenity`

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)
