#!/bin/bash

mkdir -p oem/after/pkgs/
dpkg-deb -b --root-owner-group calamares-settings/ \
    oem/after/pkgs/calamares-settings-minibuntu-ice.deb
dpkg-deb -b --root-owner-group mate-admin-tools-4all/ \
    oem/after/pkgs/mate-admin-tools-4all.deb