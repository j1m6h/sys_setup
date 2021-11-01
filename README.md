# Purpose
This has been specifically designed to automate the installation process of Gentoo Linux. With an automated 3 phase setup process, user interaction isn't necessarily mandatory. The simple process is as follows :
  1. baseinst_gent.sh gets executed first.
  2. envinst_gent.sh gets executed second.
  3. dldotf.sh gets executed last.

# Explanation
  baseinst_gent.sh - automatically installs an encrypted base system.
  envinst_gent.sh - automatically installs necessary dotfile dependencies, as well as dwm, st, dmenu, and dwmblocks.
  dldotf.sh - automatically copies dotfiles from my github repo 'dotfiles' to the system
 
 # Side note
 It is not mandatory to run all three files in the order specified above, that is just for a completely fresh installation. dldotf.sh can be run whenever needed, as well as envinst_gen.sh. baseinst_gent.sh must not be executed anytime after the system is already installed, this is very important.
