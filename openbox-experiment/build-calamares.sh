#!/bin/bash

dpkg-deb -b --root-owner-group calamares-settings/ \
    oem/after/pkgs/calamares-settings-minibuntu-canon.deb
