/*
 * Copyright 2017-2023 elementary, Inc. (https://elementary.io)
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
 */

public class Network.VpnMenuItem : Gtk.FlowBoxChild {
    public NM.RemoteConnection remote_connection { get; construct; }

    private NM.VpnConnection? _vpn_connection = null;
    public NM.VpnConnection? vpn_connection {
        get {
            return _vpn_connection;
        }

        set {
            if (value != null) {
                _vpn_connection = value;
                _vpn_connection.vpn_state_changed.connect (update_state);
            } else {
                _vpn_connection.vpn_state_changed.disconnect (update_state);
                _vpn_connection = null;

                ((Gtk.Image) toggle_button.image).icon_name = "network-vpn-disconected-symbolic";
                toggle_button.active = false;
            }

        }
    }

    private static Gtk.CssProvider provider;
    private Gtk.Label label;
    private Gtk.ToggleButton toggle_button;

    public VpnMenuItem (NM.RemoteConnection remote_connection) {
        Object (remote_connection: remote_connection);
    }

    static construct {
        provider = new Gtk.CssProvider ();
        provider.load_from_resource ("io/elementary/wingpanel/network/Indicator.css");
    }

    construct {
        toggle_button = new Gtk.ToggleButton () {
            halign = Gtk.Align.CENTER,
            image = new Gtk.Image.from_icon_name ("network-vpn-disconected-symbolic", Gtk.IconSize.MENU)
        };
        toggle_button.get_style_context ().add_class ("circular");
        toggle_button.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);


        label = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            max_width_chars = 16
        };
        label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3) {
            hexpand = true
        };
        box.add (toggle_button);
        box.add (label);

        can_focus = false;
        add (box);

        toggle_button.toggled.connect (() => {
            activate ();
        });

        update ();
        remote_connection.changed.connect (update);
    }

    private void update () {
        label.label = remote_connection.get_id ();
    }

    private void update_state () {
        switch (vpn_connection.vpn_state) {
            case NM.VpnConnectionState.CONNECT:
            case NM.VpnConnectionState.IP_CONFIG_GET:
            case NM.VpnConnectionState.NEED_AUTH:
            case NM.VpnConnectionState.PREPARE:
                ((Gtk.Image) toggle_button.image).icon_name = "network-vpn-acquiring-symbolic";
                break;
            case NM.VpnConnectionState.ACTIVATED:
                ((Gtk.Image) toggle_button.image).icon_name = "network-vpn-symbolic";
                toggle_button.active = true;
                break;
            case NM.VpnConnectionState.DISCONNECTED:
                ((Gtk.Image) toggle_button.image).icon_name = "network-vpn-disconected-symbolic";
                toggle_button.active = false;
                break;
            case NM.VpnConnectionState.FAILED:
            case NM.VpnConnectionState.UNKNOWN:
                ((Gtk.Image) toggle_button.image).icon_name = "network-vpn-error-symbolic";
                toggle_button.active = false;
                break;
        }
    }
}
