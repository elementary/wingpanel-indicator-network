# Wingpanel Network Indicator
[![l10n](https://l10n.elementary.io/widgets/wingpanel/wingpanel-indicator-network/svg-badge.svg)](https://l10n.elementary.io/projects/wingpanel/wingpanel-indicator-network)

![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* cmake
* gobject-introspection
* libgranite-dev
* libnm-dev
* libnma-dev
* libwingpanel-2.0-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/

Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make

To install, use `make install`

    sudo make install
