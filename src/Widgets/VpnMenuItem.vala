/*
* SPDX-License-Identifier: LGPL-2.1-or-later
* SPDX-FileCopyrightText: 2017-2023 elementary, Inc. (https://elementary.io)
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
                update_state ();
            } else {
                _vpn_connection.vpn_state_changed.disconnect (update_state);
                _vpn_connection = null;

                ((Gtk.Image) toggle_button.image).icon_name = "network-vpn-disconnected-symbolic";
                toggle_button.active = false;
            }

        }
    }

    private static Gtk.CssProvider provider;
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
            image = new Gtk.Image.from_icon_name ("network-vpn-disconnected-symbolic", Gtk.IconSize.MENU)
        };
        toggle_button.get_style_context ().add_class ("circular");
        toggle_button.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);


        var label = new Gtk.Label (remote_connection.get_id ()) {
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

        remote_connection.changed.connect (() => {
            label.label = remote_connection.get_id ();
        });
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
                ((Gtk.Image) toggle_button.image).icon_name = "network-vpn-connected-symbolic";
                toggle_button.active = true;
                break;
            case NM.VpnConnectionState.DISCONNECTED:
                ((Gtk.Image) toggle_button.image).icon_name = "network-vpn-disconnected-symbolic";
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
