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

    uint animation_timeout;
    int animation_state = 0;

    public DisplayWidget () {
        Object (orientation: Gtk.Orientation.HORIZONTAL);
    }

    construct {
        image = new Gtk.Image ();
        image.icon_name = "network-wired-symbolic";

        pack_start (image);
    }

    public void update_state (Network.State state, bool secure) {
        if (animation_timeout > 0) {
            Source.remove (animation_timeout);
            animation_timeout = 0;
        }

        switch (state) {
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
            animation_timeout = Timeout.add (300, () => {
                animation_state = (animation_state + 1) % 4;
                string strength = "";
                switch (animation_state) {
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
        case Network.State.DISCONNECTED:
            image.icon_name = "network-offline-symbolic";
            break;
        default:
            image.icon_name = "network-offline-symbolic";
            critical("Unknown network state, cannot show the good icon: %s", state.to_string());
            break;
        }
    }
}
