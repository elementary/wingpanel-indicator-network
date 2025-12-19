# Wingpanel Network Indicator
[![Translation status](https://l10n.elementary.io/widgets/wingpanel/-/wingpanel-indicator-network/svg-badge.svg)](https://l10n.elementary.io/engage/wingpanel/?utm_source=widget)

![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* gobject-introspection
* libglib2.0-dev (>= 2.74)
* libgranite-7-dev
* libnm-dev (>= 1.24)
* libnma-gtk4-dev
* libpolkit-gobject-1-dev
* libwingpanel-8-dev
* meson
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
