#!/bin/bash

mkdir -p oem/after/pkgs/
dpkg-deb -b --root-owner-group calamares-settings/ \
    oem/after/pkgs/calamares-settings-minibuntu-canon.deb
dpkg-deb -b --root-owner-group mate-time-admin/ \
    oem/after/pkgs/mate-time-admin.deb