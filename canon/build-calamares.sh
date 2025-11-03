#!/bin/bash

dpkg-deb -b --root-owner-group calamares-settings-calatest/ \
    oem/after/pkgs/calamares-settings-calatest.deb
