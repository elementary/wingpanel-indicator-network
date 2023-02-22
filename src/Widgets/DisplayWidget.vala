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
    private Gtk.Image image;
    private Gtk.Label extra_info_label;
    private Gtk.Revealer extra_info_revealer;
    private Gtk.Revealer vpn_revealer;
    private NM.Client nm_client;
    private NM.VpnConnection? active_vpn_connection = null;

    private uint wifi_animation_timeout;
    private int wifi_animation_state = 0;
    private uint cellular_animation_timeout;
    private int cellular_animation_state = 0;

    construct {
        image = new Gtk.Image.from_icon_name ("panel-network-wired-connected-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

        extra_info_label = new Gtk.Label (null) {
            margin_start = 4,
            valign = Gtk.Align.CENTER,
            vexpand = true
        };

        extra_info_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        extra_info_revealer.add (extra_info_label);

        var vpn_image = new Gtk.Image.from_icon_name ("network-vpn-connected-symbolic", Gtk.IconSize.MENU) {
            margin_start = 6
        };

        vpn_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        vpn_revealer.add (vpn_image);

        add (image);
        add (extra_info_revealer);

        try {
            nm_client = new NM.Client ();

            update_vpn_connection ();
            nm_client.notify["active-connections"].connect (update_vpn_connection);
        } catch (Error e) {
            critical (e.message);
        }
    }

    public void update_state (Network.State state, string? extra_info = null) {
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
        case Network.State.DISCONNECTED_AIRPLANE_MODE:
            image.icon_name = "airplane-mode-symbolic";
            break;
        case Network.State.CONNECTING_WIRED:
            image.icon_name = "panel-network-wired-acquiring-symbolic";
            break;
        case Network.State.CONNECTED_WIRED:
            image.icon_name = "panel-network-wired-connected-symbolic";
            break;
        case Network.State.CONNECTED_WIFI_WEAK:
            image.icon_name = "panel-network-wireless-signal-weak-symbolic";
            break;
        case Network.State.CONNECTED_WIFI_OK:
            image.icon_name = "panel-network-wireless-signal-ok-symbolic";
            break;
        case Network.State.CONNECTED_WIFI_GOOD:
            image.icon_name = "panel-network-wireless-signal-good-symbolic";
            break;
        case Network.State.CONNECTED_WIFI_EXCELLENT:
            image.icon_name = "panel-network-wireless-signal-excellent-symbolic";
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
                image.icon_name = "panel-network-wireless-signal-%s-symbolic".printf (strength);
                return true;
            });
            break;
        case Network.State.CONNECTED_MOBILE_WEAK:
            image.icon_name = "panel-network-cellular-signal-weak-symbolic";
            break;
        case Network.State.CONNECTED_MOBILE_OK:
            image.icon_name = "panel-network-cellular-signal-ok-symbolic";
            break;
        case Network.State.CONNECTED_MOBILE_GOOD:
            image.icon_name = "panel-network-cellular-signal-good-symbolic";
            break;
        case Network.State.CONNECTED_MOBILE_EXCELLENT:
            image.icon_name = "panel-network-cellular-signal-excellent-symbolic";
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

                image.icon_name = "panel-network-cellular-signal-%s-symbolic".printf (strength);
                return true;
            });
            break;
        case Network.State.FAILED_MOBILE:
            image.icon_name = "panel-network-cellular-offline-symbolic";
            break;
        case Network.State.FAILED_WIFI:
        case Network.State.DISCONNECTED:
            image.icon_name = "panel-network-wireless-offline-symbolic";
            break;
        case Network.State.WIRED_UNPLUGGED:
            image.icon_name = "panel-network-wired-offline-symbolic";
            break;
        default:
            image.icon_name = "panel-network-wired-offline-symbolic";
            critical ("Unknown network state, cannot show the good icon: %s", state.to_string ());
            break;
        }
    }

    private void update_vpn_connection () {
        active_vpn_connection.vpn_state_changed.disconnect (reveal_vpn);
        active_vpn_connection = null;

        nm_client.get_active_connections ().foreach ((connection) => {
            if (active_vpn_connection == null && connection.vpn) {
                active_vpn_connection = (NM.VpnConnection) connection;
                active_vpn_connection.vpn_state_changed.connect (reveal_vpn);
            }
        });

        reveal_vpn ();
    }

    private void reveal_vpn () {
        if (active_vpn_connection != null && active_vpn_connection.get_vpn_state () == NM.VpnConnectionState.ACTIVATED) {
            vpn_revealer.reveal_child = true;
        } else {
            vpn_revealer.reveal_child = false;
        }
    }
}
