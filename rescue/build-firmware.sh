#!/bin/bash

dpkg-deb -b --root-owner-group linux-firmware-rescue/ \
    oem/before/pkgs/linux-firmware-rescue.deb
