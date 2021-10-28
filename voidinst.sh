#!/bin/bash

if [ "$EUID" -ne 0 ]; then
	echo "**Must be root in order to install dependencies**"
	exit
fi

echo "Gathering deps..."
xbps-install -S xorg base-devel libX11-devel libXft-devel libXinerama-devel git picom feh lsd

outputdir="/usr/local/src/"
mkdir /usr/local/src

git clone https://github.com/j1m6h/dwm $outputdir/dwm
git clone https://github.com/j1m6h/st $outputdir/st
git clone https://github.com/j1m6h/dmenu $outputdir/dmenu
git clone https://github.com/j1m6h/dwmblocks $outputdir/dwmblocks

cd /usr/local/src/dwm && make clean install 
cd ../st && make clean install
cd ../dmenu && make clean install
cd ../dwmblocks && make clean install
