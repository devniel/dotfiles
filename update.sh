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
# yazi file manager (install via ubuntu/apps/install.sh)
cp $HOME/.config/yazi/yazi.toml ./ubuntu/yazi/yazi.toml
# polybar: only the customized grayblocks files (see ubuntu/polybar/README.md)
cp $HOME/.config/polybar/grayblocks/config.ini ./ubuntu/polybar/grayblocks/config.ini
cp $HOME/.config/polybar/grayblocks/colors.ini ./ubuntu/polybar/grayblocks/colors.ini
cp $HOME/.config/polybar/grayblocks/scripts/rofi/colors.rasi ./ubuntu/polybar/grayblocks/scripts/rofi/colors.rasi
cp $HOME/.config/picom/picom.conf ./ubuntu/picom/picom.conf
cp $HOME/.config/nitrogen/nitrogen.cfg ./ubuntu/nitrogen/nitrogen.cfg
# right-side monitor split (black left strip) + login autostart
cp $HOME/.local/bin/right-screen.sh ./ubuntu/.local/bin/right-screen.sh
cp $HOME/.xsessionrc ./ubuntu/.xsessionrc
# font rendering (UI scaling is set by screen-native.sh / screen-hd.sh)
cp $HOME/.Xresources ./ubuntu/.Xresources
# login default, native res + 2x scaling (run from .xsessionrc): screen-native.sh / screen-native.sh --reset
cp $HOME/.local/bin/screen-native.sh ./ubuntu/.local/bin/screen-native.sh
# 1080p at 1x (auto-detects the connected output): screen-hd.sh
cp $HOME/.local/bin/screen-hd.sh ./ubuntu/.local/bin/screen-hd.sh

# hyprland desktop (see ubuntu/hyprland/README.md): compositor config + the apps it launches
cp $HOME/.config/hypr/hyprland.lua ./ubuntu/hyprland/hyprland.lua
cp $HOME/.config/hypr/monitors.lua ./ubuntu/hyprland/monitors.lua
cp $HOME/.config/hypr/hyprland-gui.lua ./ubuntu/hyprland/hyprland-gui.lua
cp $HOME/.config/hypr/hyprpaper.conf ./ubuntu/hyprland/hyprpaper.conf
cp $HOME/.config/hypr/hypridle.conf ./ubuntu/hyprland/hypridle.conf
cp $HOME/.config/hypr/hyprlock.conf ./ubuntu/hyprland/hyprlock.conf
cp $HOME/hyprland-build/build.sh ./ubuntu/hyprland/build.sh
cp $HOME/.config/waybar/config.jsonc ./ubuntu/waybar/config.jsonc
cp $HOME/.config/waybar/style.css ./ubuntu/waybar/style.css
cp $HOME/.config/rofi/config.rasi ./ubuntu/rofi/config.rasi
cp $HOME/.config/mako/config ./ubuntu/mako/config
cp $HOME/.config/kitty/kitty.conf ./ubuntu/kitty/kitty.conf
