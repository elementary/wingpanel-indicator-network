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
    private ConnectionRevealer cellular_revealer;
    private ConnectionRevealer vpn_revealer;
    private ConnectionRevealer wifi_revealer;
    private ConnectionRevealer wired_revealer;
    private ConnectionRevealer network_revealer;

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

    private ConnectionState cellular_connection_state = ConnectionState.DISCONNECTED;
    private ConnectionState wifi_connection_state = ConnectionState.DISCONNECTED;
    private ConnectionState wired_connection_state = ConnectionState.DISCONNECTED;

    construct {
        cellular_revealer = new ConnectionRevealer.from_icon_name ("network-cellular-offline-symbolic");

        vpn_revealer = new ConnectionRevealer.from_icon_name ("network-vpn-symbolic");

        wifi_revealer = new ConnectionRevealer.from_icon_name ("network-wireless-offline-symbolic");

        wired_revealer = new ConnectionRevealer.from_icon_name ("network-wired-offline-symbolic");

        network_revealer = new ConnectionRevealer.from_icon_name ("network-offline-symbolic") {
            reveal_child = true
        };

        extra_info_label = new Gtk.Label (null) {
            margin_start = 4,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };

        extra_info_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        extra_info_revealer.add (extra_info_label);

        add (vpn_revealer);
        add (wired_revealer);
        add (wifi_revealer);
        add (cellular_revealer);
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
            network_revealer.image.icon_name = "network-offline-symbolic";
            cellular_connection_state = ConnectionState.DISCONNECTED;
            wifi_connection_state = ConnectionState.DISCONNECTED;
            wired_connection_state = ConnectionState.DISCONNECTED;
            update_icons ();
            break;
        case Network.State.DISCONNECTED_AIRPLANE_MODE:
            network_revealer.image.icon_name = "airplane-mode-symbolic";
            cellular_connection_state = ConnectionState.DISCONNECTED;
            wifi_connection_state = ConnectionState.DISCONNECTED;
            wired_connection_state = ConnectionState.DISCONNECTED;
            update_icons ();
            break;
        case Network.State.DISCONNECTED_WIRED:
            wired_revealer.image.icon_name = "network-wired-disconnected";
            wired_connection_state = ConnectionState.DISCONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_VPN:
            vpn_revealer.reveal_child = true;
            break;
        case Network.State.FAILED_VPN:
            vpn_revealer.reveal_child = false;
            break;
        case Network.State.CONNECTING_WIRED:
            wired_revealer.image.icon_name = "network-wired-acquiring-symbolic";
            wired_connection_state = ConnectionState.CONNECTING;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIRED:
            wired_revealer.image.icon_name = "network-wired-%ssymbolic".printf (secure? "secure-" : "");
            wired_connection_state = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIFI:
            wifi_revealer.image.icon_name = "network-wireless-connected-symbolic";
            wifi_connection_state = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIFI_WEAK:
            wifi_revealer.image.icon_name = "network-wireless-signal-weak-%ssymbolic".printf (secure? "secure-" : "");
            wifi_connection_state = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIFI_OK:
            wifi_revealer.image.icon_name = "network-wireless-signal-ok-%ssymbolic".printf (secure? "secure-" : "");
            wifi_connection_state = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIFI_GOOD:
            wifi_revealer.image.icon_name = "network-wireless-signal-good-%ssymbolic".printf (secure? "secure-" : "");
            wifi_connection_state = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_WIFI_EXCELLENT:
            wifi_revealer.image.icon_name = "network-wireless-signal-excellent-%ssymbolic".printf (secure? "secure-" : "");
            wifi_connection_state = ConnectionState.CONNECTED;
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
                wifi_revealer.image.icon_name = "network-wireless-signal-" + strength + (secure? "-secure" : "") + "-symbolic";
                wifi_connection_state = ConnectionState.CONNECTING;
                update_icons ();
                return true;
            });
            break;
        case Network.State.CONNECTED_MOBILE_WEAK:
            cellular_revealer.image.icon_name = "network-cellular-signal-weak-%ssymbolic".printf (secure ? "secure-" : "");
            cellular_connection_state = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_MOBILE_OK:
            cellular_revealer.image.icon_name = "network-cellular-signal-ok-%ssymbolic".printf (secure ? "secure-" : "");
            cellular_connection_state = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_MOBILE_GOOD:
            cellular_revealer.image.icon_name = "network-cellular-signal-good-%ssymbolic".printf (secure ? "secure-" : "");
            cellular_connection_state = ConnectionState.CONNECTED;
            update_icons ();
            break;
        case Network.State.CONNECTED_MOBILE_EXCELLENT:
            cellular_revealer.image.icon_name = "network-cellular-signal-excellent-%ssymbolic".printf (secure ? "secure-" : "");
            cellular_connection_state = ConnectionState.CONNECTED;
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

                cellular_revealer.image.icon_name = "network-cellular-signal-" + strength + (secure ? "secure-" : "") + "-symbolic";
                cellular_connection_state = ConnectionState.CONNECTING;
                update_icons ();
                return true;
            });
            break;
        case Network.State.FAILED_MOBILE:
            cellular_revealer.image.icon_name = "network-cellular-offline-symbolic";
            cellular_connection_state = ConnectionState.DISCONNECTED;
            update_icons ();
            break;
        case Network.State.FAILED_WIFI:
            wifi_revealer.image.icon_name = "network-wireless-offline-symbolic";
            wifi_connection_state = ConnectionState.DISCONNECTED;
            update_icons ();
            break;
        case Network.State.FAILED_WIRED:
        case Network.State.WIRED_UNPLUGGED:
            wired_revealer.image.icon_name = "network-wired-offline-symbolic";
            wired_connection_state = ConnectionState.DISCONNECTED;
            update_icons ();
            break;
        default:
            network_revealer.image.icon_name = "network-offline-symbolic";
            cellular_connection_state = ConnectionState.DISCONNECTED;
            wifi_connection_state = ConnectionState.DISCONNECTED;
            wired_connection_state = ConnectionState.DISCONNECTED;
            update_icons ();
            critical ("Unknown network state, cannot show the good icon: %s", state.to_string ());
            break;
        }
    }

    private void update_icons () {
        if ((cellular_connection_state + wifi_connection_state + wired_connection_state) > 0) {
            network_revealer.reveal_child = false;
        } else {
            cellular_revealer.reveal_child = false;
            wifi_revealer.reveal_child = false;
            wired_revealer.reveal_child = false;
            network_revealer.reveal_child = true;

            return;
        }

        if (cellular_connection_state > 0) {
            cellular_revealer.reveal_child = true;
        } else {
            cellular_revealer.reveal_child = false;
        }

        if (wifi_connection_state > 0) {
            wifi_revealer.reveal_child = true;
        } else {
            wifi_revealer.reveal_child = false;
        }

        if (wired_connection_state > 0) {
            wired_revealer.reveal_child = true;
        } else {
            wired_revealer.reveal_child = false;
        }
    }

    private class ConnectionRevealer : Gtk.Revealer {
        public Gtk.Image image { get; construct set; }

        public ConnectionRevealer.from_icon_name (string icon_name) {
            image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.LARGE_TOOLBAR);
        }

        construct {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;

            add (image);
        }
    }
}
