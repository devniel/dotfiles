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
cp $HOME/.config/polybar/launch.sh ./ubuntu/polybar/launch.sh
cp -r $HOME/.config/polybar/grayblocks/. ./ubuntu/polybar/grayblocks/
cp $HOME/.config/picom/picom.conf ./ubuntu/picom/picom.conf
cp $HOME/.config/nitrogen/nitrogen.cfg ./ubuntu/nitrogen/nitrogen.cfg
