/*
* Copyright (c) 2015-2016 elementary LLC (http://launchpad.net/wingpanel-indicator-network)
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

public class Network.Widgets.DisplayWidget : Gtk.Box {
    private Gtk.Image image;
    private Gtk.Label extra_info_label;
    private Gtk.Revealer extra_info_revealer;

    uint wifi_animation_timeout;
    int wifi_animation_state = 0;
    uint cellular_animation_timeout;
    int cellular_animation_state = 0;

    public DisplayWidget () {
        Object (orientation: Gtk.Orientation.HORIZONTAL);
    }

    construct {
        image = new Gtk.Image ();
        image.icon_name = "network-wired-symbolic";
        image.icon_size = Gtk.IconSize.LARGE_TOOLBAR;

        extra_info_label = new Gtk.Label (null);
        extra_info_label.margin_start = 4;
        extra_info_label.valign = Gtk.Align.CENTER;
        extra_info_label.vexpand = true;

        extra_info_revealer = new Gtk.Revealer ();
        extra_info_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        extra_info_revealer.add (extra_info_label);

        pack_start (image);
        pack_start (extra_info_revealer);
    }

    public void update_state (Network.State state, bool secure, string? extra_info = null) {
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
            image.icon_name = "network-wired-acquiring-symbolic";
            break;
        case Network.State.CONNECTED_WIRED:
            image.icon_name = "network-wired-%ssymbolic".printf (secure? "secure-" : "");
            break;
        case Network.State.CONNECTED_WIFI:
            image.icon_name = "network-wireless-connected-symbolic";
            break;
        case Network.State.CONNECTED_WIFI_WEAK:
            image.icon_name = "network-wireless-signal-weak-%ssymbolic".printf (secure? "secure-" : "");
            break;
        case Network.State.CONNECTED_WIFI_OK:
            image.icon_name = "network-wireless-signal-ok-%ssymbolic".printf (secure? "secure-" : "");
            break;
        case Network.State.CONNECTED_WIFI_GOOD:
            image.icon_name = "network-wireless-signal-good-%ssymbolic".printf (secure? "secure-" : "");
            break;
        case Network.State.CONNECTED_WIFI_EXCELLENT:
            image.icon_name = "network-wireless-signal-excellent-%ssymbolic".printf (secure? "secure-" : "");
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
                image.icon_name = "network-wireless-signal-" + strength + (secure? "-secure" : "") + "-symbolic";
                return true;
            });
            break;
        case Network.State.CONNECTED_MOBILE_WEAK:
            image.icon_name = "network-cellular-signal-weak-%ssymbolic".printf (secure ? "secure-" : "");
            break;
        case Network.State.CONNECTED_MOBILE_OK:
            image.icon_name = "network-cellular-signal-ok-%ssymbolic".printf (secure ? "secure-" : "");
            break;
        case Network.State.CONNECTED_MOBILE_GOOD:
            image.icon_name = "network-cellular-signal-good-%ssymbolic".printf (secure ? "secure-" : "");
            break;
        case Network.State.CONNECTED_MOBILE_EXCELLENT:
            image.icon_name = "network-cellular-signal-excellent-%ssymbolic".printf (secure ? "secure-" : "");
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

                image.icon_name = "network-cellular-signal-" + strength + (secure ? "secure-" : "")  + "-symbolic";
                return true;
            });
            break;
        case Network.State.FAILED_MOBILE:
            image.icon_name = "network-cellular-offline-symbolic";
            break;
        case Network.State.DISCONNECTED:
            image.icon_name = "network-wireless-offline-symbolic";
            break;
        case Network.State.WIRED_UNPLUGGED:
            image.icon_name = "network-wired-offline-symbolic";
            break;
        default:
            image.icon_name = "network-offline-symbolic";
            critical("Unknown network state, cannot show the good icon: %s", state.to_string());
            break;
        }
    }
}
