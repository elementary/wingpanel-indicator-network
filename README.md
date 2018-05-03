# Wingpanel Network Indicator
[![l10n](https://l10n.elementary.io/widgets/wingpanel/wingpanel-indicator-network/svg-badge.svg)](https://l10n.elementary.io/projects/wingpanel/wingpanel-indicator-network)

![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* gobject-introspection
* libgranite-dev
* libnm-dev
* libnma-dev
* libwingpanel-2.0-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
