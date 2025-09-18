#!/bin/bash

sleep 1

WALLPAPER=/usr/local/share/minibuntu-rescue/background.jpg
for prop in $(xfconf-query -lc xfce4-desktop | grep last-image$); do
    xfconf-query -c xfce4-desktop -p "$prop" -s "$WALLPAPER"
done
