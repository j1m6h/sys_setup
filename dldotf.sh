#!/bin/bash

echo "Downloading dotfiles..."
curl https://raw.githubusercontent.com/j1m6h/dotfiles/main/.xinitrc > ~/.xinitrc
curl https://raw.githubusercontent.com/j1m6h/dotfiles/main/.bashrc > ~/.bashrc
curl https://raw.githubusercontent.com/j1m6h/dotfiles/main/.bash_profile > ~/.bash_profile
curl https://raw.githubusercontent.com/j1m6h/dotfiles/main/.config/nvim/init.vim > ~/.config/nvim/init.vim
echo "Finished."
