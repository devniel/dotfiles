#!/bin/bash
cp $HOME/.zshrc ./zsh/.zshrc
cp $HOME/.aliases ./zsh/.aliases
cp $HOME/.variables ./zsh/.variables

# xubuntu desktop
cp $HOME/.xbindkeysrc ./ubuntu/.xbindkeysrc
cp $HOME/.config/i3/config ./ubuntu/i3/config
cp $HOME/.config/i3/ws-next.sh ./ubuntu/i3/ws-next.sh
cp $HOME/.config/i3/ws-prev.sh ./ubuntu/i3/ws-prev.sh
cp $HOME/.config/ghostty/config ./ubuntu/ghostty/config
# polybar: only the customized grayblocks files (see ubuntu/polybar/README.md)
cp $HOME/.config/polybar/grayblocks/config.ini ./ubuntu/polybar/grayblocks/config.ini
cp $HOME/.config/polybar/grayblocks/colors.ini ./ubuntu/polybar/grayblocks/colors.ini
cp $HOME/.config/polybar/grayblocks/scripts/rofi/colors.rasi ./ubuntu/polybar/grayblocks/scripts/rofi/colors.rasi
cp $HOME/.config/picom/picom.conf ./ubuntu/picom/picom.conf
cp $HOME/.config/nitrogen/nitrogen.cfg ./ubuntu/nitrogen/nitrogen.cfg
