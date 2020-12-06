/*
* Copyright 2015-2020 elementary, Inc. (https://elementary.io)
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Library General Public License as published by
* the Free Software Foundation, either version 2.1 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Library General Public License for more details.
*
* You should have received a copy of the GNU Library General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*
*/

public class Network.Widgets.DisplayWidget : Gtk.Grid {
    private Gtk.Image cellular_image;
    private Gtk.Revealer cellular_revealer;

    private Gtk.Image vpn_image;
    private Gtk.Revealer vpn_revealer;

    private Gtk.Image wifi_image;
    private Gtk.Revealer wifi_revealer;

    private Gtk.Image wired_image;
    private Gtk.Revealer wired_revealer;

    private Gtk.Image network_image;
    private Gtk.Revealer network_revealer;

    private Gtk.Label extra_info_label;
    private Gtk.Revealer extra_info_revealer;

    private uint wifi_animation_timeout;
    private int wifi_animation_state = 0;
    private uint cellular_animation_timeout;
    private int cellular_animation_state = 0;

    private enum ConnectionState {
        DISCONNECTED = 0,
        CONNECTING = 1,
        CONNECTED = 2
    }

    private ConnectionState cellular_connected = ConnectionState.DISCONNECTED;
    private ConnectionState wifi_connected = ConnectionState.DISCONNECTED;
    private ConnectionState wired_connected = ConnectionState.DISCONNECTED;

    construct {
        cellular_image = new Gtk.Image.from_icon_name ("network-cellular-offline-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        cellular_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        cellular_revealer.add (cellular_image);

        vpn_image = new Gtk.Image.from_icon_name ("network-vpn", Gtk.IconSize.LARGE_TOOLBAR);

        vpn_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        vpn_revealer.add (vpn_image);

        wifi_image = new Gtk.Image.from_icon_name ("network-wireless-offline-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        wifi_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        wifi_revealer.add (wifi_image);

        wired_image = new Gtk.Image.from_icon_name ("network-wired-offline-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        wired_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        wired_revealer.add (wired_image);

        network_image = new Gtk.Image.from_icon_name ("network-offline-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        network_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            reveal_child = true
        };
        network_revealer.add (network_image);

        extra_info_label = new Gtk.Label (null) {
            margin_start = 4,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };

        extra_info_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        extra_info_revealer.add (extra_info_label);

        add (cellular_revealer);
        add (vpn_revealer);
        add (wifi_revealer);
        add (wired_revealer);
        add (network_revealer);
        add (extra_info_revealer);

        update_icons ();
    }

    public void update_state (Network.State state, bool secure, string? extra_info = null) {
        info ("Network state changed to \"%s\"\n", state.to_string ());

        extra_info_revealer.reveal_child = extra_info != null;
        extra_info_label.label = extra_info;

        if (wifi_animation_timeout > 0) {
            Source.remove (wifi_animation_timeout);
            wifi_animation_timeout = 0;
        }

        if (cellular_animation_timeout > 0) {
            Source.remove (cellular_animation_timeout);
            cellular_animation_timeout = 0;
        }

        switch (state) {
        case Network.State.DISCONNECTED:
            network_image.icon_name = "network-offline-symbolic";
            cellular_connected = ConnectionState.DISCONNECTED;
            wifi_connected = ConnectionState.DISCONNECTED;
            wired_connected = ConnectionState.DISCONNECTED;
            update_icons ();
            break;
        case Network.State.DISCONNECTED_AIRPLANE_MODE:
            network_image.icon_name = "airplane-mode-symbolic";
            cellular_connected = ConnectionState.DISCONNECTED;
            wifi_connected = ConnectionState.DISCONNECTED;
            wired_connected = ConnectionState.DISCONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTING_WIRED:
            wired_image.icon_name = "network-wired-acquiring-symbolic";
            wired_connected = ConnectionState.CONNECTING;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIRED:
            wired_image.icon_name = "network-wired-%ssymbolic".printf (secure? "secure-" : "");
            wired_connected = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIFI:
            wifi_image.icon_name = "network-wireless-connected-symbolic";
            wifi_connected = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIFI_WEAK:
            wifi_image.icon_name = "network-wireless-signal-weak-%ssymbolic".printf (secure? "secure-" : "");
            wifi_connected = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIFI_OK:
            wifi_image.icon_name = "network-wireless-signal-ok-%ssymbolic".printf (secure? "secure-" : "");
            wifi_connected = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIFI_GOOD:
            wifi_image.icon_name = "network-wireless-signal-good-%ssymbolic".printf (secure? "secure-" : "");
            wifi_connected = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIFI_EXCELLENT:
            wifi_image.icon_name = "network-wireless-signal-excellent-%ssymbolic".printf (secure? "secure-" : "");
            wifi_connected = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTING_WIFI:
            wifi_animation_timeout = Timeout.add (300, () => {
                wifi_animation_state = (wifi_animation_state + 1) % 4;
                string strength = "";
                switch (wifi_animation_state) {
                case 0:
                    strength = "weak";
                    break;
                case 1:
                    strength = "ok";
                    break;
                case 2:
                    strength = "good";
                    break;
                case 3:
                    strength = "excellent";
                    break;
                }
                wifi_image.icon_name = "network-wireless-signal-" + strength + (secure? "-secure" : "") + "-symbolic";
                wifi_connected = ConnectionState.CONNECTING;
                update_icons ();
                return true;
            });
            break;
        case Network.State.CONNECTED_MOBILE_WEAK:
            cellular_image.icon_name = "network-cellular-signal-weak-%ssymbolic".printf (secure ? "secure-" : "");
            cellular_connected = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_MOBILE_OK:
            cellular_image.icon_name = "network-cellular-signal-ok-%ssymbolic".printf (secure ? "secure-" : "");
            cellular_connected = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_MOBILE_GOOD:
            cellular_image.icon_name = "network-cellular-signal-good-%ssymbolic".printf (secure ? "secure-" : "");
            cellular_connected = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_MOBILE_EXCELLENT:
            cellular_image.icon_name = "network-cellular-signal-excellent-%ssymbolic".printf (secure ? "secure-" : "");
            cellular_connected = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTING_MOBILE:
            cellular_animation_timeout = Timeout.add (300, () => {
                cellular_animation_state = (cellular_animation_state + 1) % 4;
                string strength = "";
                switch (cellular_animation_state) {
                case 0:
                    strength = "weak";
                    break;
                case 1:
                    strength = "ok";
                    break;
                case 2:
                    strength = "good";
                    break;
                case 3:
                    strength = "excellent";
                    break;
                }

                cellular_image.icon_name = "network-cellular-signal-" + strength + (secure ? "secure-" : "") + "-symbolic";
                cellular_connected = ConnectionState.CONNECTING;
                update_icons ();
                return true;
            });
            break;
        case Network.State.FAILED_MOBILE:
            cellular_image.icon_name = "network-cellular-offline-symbolic";
            cellular_connected = ConnectionState.DISCONNECTED;
            update_icons ();
            break;
        case Network.State.FAILED_WIFI:
            wifi_image.icon_name = "network-wireless-offline-symbolic";
            wifi_connected = ConnectionState.DISCONNECTED;
            update_icons ();
            break;
        case Network.State.WIRED_UNPLUGGED:
            wired_image.icon_name = "network-wired-offline-symbolic";
            wired_connected = ConnectionState.DISCONNECTED;
            update_icons ();
            break;
        default:
            network_image.icon_name = "network-offline-symbolic";
            cellular_connected = ConnectionState.DISCONNECTED;
            wifi_connected = ConnectionState.DISCONNECTED;
            wired_connected = ConnectionState.DISCONNECTED;
            update_icons ();
            critical ("Unknown network state, cannot show the good icon: %s", state.to_string ());
            break;
        }
    }

    private void update_icons () {
        if ((cellular_connected + wifi_connected + wired_connected) > 0) {
            network_revealer.reveal_child = false;
        } else {
            cellular_revealer.reveal_child = false;
            wifi_revealer.reveal_child = false;
            wired_revealer.reveal_child = false;
            network_revealer.reveal_child = true;

            return;
        }

        if (cellular_connected > 0) {
            cellular_revealer.reveal_child = true;
        } else {
            cellular_revealer.reveal_child = false;
        }

        if (wifi_connected > 0) {
            wifi_revealer.reveal_child = true;
        } else {
            wifi_revealer.reveal_child = false;
        }

        if (wired_connected > 0) {
            wired_revealer.reveal_child = true;
        } else {
            wired_revealer.reveal_child = false;
        }
    }
}
