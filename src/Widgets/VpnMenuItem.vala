/*
* SPDX-License-Identifier: LGPL-2.1-or-later
* SPDX-FileCopyrightText: 2017-2023 elementary, Inc. (https://elementary.io)
*/

public class Network.VpnMenuItem : Gtk.FlowBoxChild {
    public NM.RemoteConnection remote_connection { get; construct; }
    public Cancellable? cancellable = null;

    private NM.ActiveConnection? _vpn_connection = null;
    public NM.ActiveConnection? vpn_connection {
        get {
            return _vpn_connection;
        }
        set {
            if (value != null) {
                _vpn_connection = value;
                /* We cannot rely on the sole state_changed signal, as it will
                 * silently ignore sub-vpn specific states, like tun/tap
                 * interface connection etc. That's why we keep a separate
                 * implementation for the signal handlers. */
                if (value.get_vpn ()) {
                    ((NM.VpnConnection)_vpn_connection).vpn_state_changed.connect (update_state);
                } else {
                    _vpn_connection.state_changed.connect (update_state);
                }
                update_state ();
                return;
            }
            if (_vpn_connection != null) {
                if (_vpn_connection.get_vpn ()) {
                    ((NM.VpnConnection)_vpn_connection).vpn_state_changed.disconnect (update_state);
                } else {
                    _vpn_connection.state_changed.disconnect (update_state);
                }
                _vpn_connection = null;
            }

            toggle_button.icon_name = "panel-network-vpn-disconnected-symbolic";
            toggle_button.active = false;
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
            icon_name = "panel-network-vpn-disconnected-symbolic"
        };
        toggle_button.add_css_class ("circular");
        toggle_button.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);


        var label = new Gtk.Label (remote_connection.get_id ()) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            max_width_chars = 16
        };
        label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3) {
            hexpand = true
        };
        box.append (toggle_button);
        box.append (label);

        can_focus = false;
        child = box;

        // We can't use clicked because we get in a weird loop state
        toggle_button.button_release_event.connect ((b, ev) => {
            activate ();
            return Gdk.EVENT_STOP;
        });

        remote_connection.changed.connect (() => {
            label.label = remote_connection.get_id ();
        });
    }

    private void update_state () {
        if (_vpn_connection == null) {
            toggle_button.icon_name = "panel-network-vpn-disconnected-symbolic";
            toggle_button.active = false;
            return;
        }
        unowned string connection_type = _vpn_connection.get_connection_type ();
        if (connection_type == NM.SettingVpn.SETTING_NAME) {
            switch (((NM.VpnConnection)_vpn_connection).vpn_state) {
                case NM.VpnConnectionState.CONNECT:
                case NM.VpnConnectionState.IP_CONFIG_GET:
                case NM.VpnConnectionState.NEED_AUTH:
                case NM.VpnConnectionState.PREPARE:
                    toggle_button.icon_name = "panel-network-vpn-acquiring-symbolic";
                    break;
                case NM.VpnConnectionState.ACTIVATED:
                    toggle_button.icon_name = "panel-network-vpn-connected-symbolic";
                    toggle_button.active = true;
                    break;
                case NM.VpnConnectionState.DISCONNECTED:
                    toggle_button.icon_name = "panel-network-vpn-disconnected-symbolic";
                    toggle_button.active = false;
                    break;
                case NM.VpnConnectionState.FAILED:
                case NM.VpnConnectionState.UNKNOWN:
                    toggle_button.icon_name = "panel-network-vpn-error-symbolic";
                    toggle_button.active = false;
                    break;
            }
        } else if (connection_type == NM.SettingWireGuard.SETTING_NAME) {
            switch (_vpn_connection.get_state ()) {
                case NM.ActiveConnectionState.UNKNOWN:
                    toggle_button.icon_name = "panel-network-vpn-error-symbolic";
                    toggle_button.active = false;
                    break;
                case NM.ActiveConnectionState.DEACTIVATED:
                case NM.ActiveConnectionState.DEACTIVATING:
                    toggle_button.icon_name = "panel-network-vpn-disconnected-symbolic";
                    toggle_button.active = false;
                    break;
                case NM.ActiveConnectionState.ACTIVATING:
                    toggle_button.icon_name = "panel-network-vpn-acquiring-symbolic";
                    break;
                case NM.ActiveConnectionState.ACTIVATED:
                    toggle_button.icon_name = "panel-network-vpn-connected-symbolic";
                    toggle_button.active = true;
                    break;
            }
        }
    }
}
