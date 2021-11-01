#!/bin/sh

homedir="/home/joshua"

if [ "$EUID" -ne 0 ]; then
	echo "**Must be root in order to install dependencies**"
	exit
fi

echo "This script will reinstall dwm, st, dmenu, and dwmblocks. All current builds will be destroyed... Continue? (y/n)"
read input
if [ $input = "n" ]; then 
	exit
fi

echo "Downloading make.conf from repo"
curl https://raw.githubusercontent.com/j1m6h/sys_setup/main/make.conf > /etc/portage/make.conf

git=$(emerge -p dev-vcs/git | grep "ebuild   R")
if [ "$git" = "" ]; then
	emerge -av dev-vcs/git
fi
picom=$(emerge -p x11-misc/picom | grep "ebuild   R")
if [ "$picom" = "" ]; then
	emerge -av x11-misc/picom
fi
feh=$(emerge -p media-gfx/feh | grep "ebuild   R")
if [ "$feh" = "" ]; then
	emerge -av media-gfx/feh
fi
lsd=$(emerge -p sys-apps/lsd | grep "ebuild   R")
if [ "$lsd" = "" ]; then
	emerge -av sys-apps/lsd
fi
hack=$(emerge -p media-fonts/hack | grep "ebuild   R")
if [ "$hack" = "" ]; then
	emerge -av media-fonts/hack
fi
xinerama=$(emerge -p x11-libs/libXinerama | grep "ebuild   R")
if [ "$xinerama" = "" ]; then
	emerge -av x11-libs/libXinerama
fi

outputdir=$homedir/src
if [ ! -d $outputdir ]; then
	mkdir $outputdir
fi

if [ -d $outputdir/dwm ]; then
	rm -r $outputdir/dwm
fi

if [ -d $outputdir/st ]; then
	rm -r $outputdir/st
fi

if [ -d $outputdir/dmenu ]; then
	rm -r $outputdir/dmenu
fi

if [ -d $outputdir/dwmblocks ]; then
	rm -r $outputdir/dwmblocks
fi

git clone https://github.com/j1m6h/dwm $outputdir/dwm
git clone https://github.com/j1m6h/st $outputdir/st
git clone https://github.com/j1m6h/dmenu $outputdir/dmenu
git clone https://github.com/j1m6h/dwmblocks $outputdir/dwmblocks

cd $outputdir/dwm && make clean install 
cd ../st && make clean install
cd ../dmenu && make clean install
cd ../dwmblocks && make clean install

if [ ! -d "$homedir/pix/ss" ]; then
	mkdir $homedir/pix/ss
fi
