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
            toggle_action.set_state (new Variant.boolean (false));
        }
    }

    private SettingsToggle toggle_button;
    private SimpleAction toggle_action;

    public VpnMenuItem (NM.RemoteConnection remote_connection) {
        Object (remote_connection: remote_connection);
    }

    construct {
        toggle_button = new SettingsToggle () {
            action_name = "vpn.toggle",
            hexpand = true,
            icon_name = "panel-network-vpn-disconnected-symbolic",
            settings_uri = "settings://network/vpn",
            text = remote_connection.get_id ()
        };

        can_focus = false;
        child = toggle_button;

        toggle_action = new SimpleAction.stateful ("toggle", null, new Variant.boolean (false));
        toggle_action.activate.connect (() => activate ());

        var action_group = new SimpleActionGroup ();
        action_group.add_action (toggle_action);

        insert_action_group ("vpn", action_group);

        remote_connection.changed.connect (() => {
            toggle_button.text = remote_connection.get_id ();
        });
    }

    private void update_state () {
        if (_vpn_connection == null) {
            toggle_button.icon_name = "panel-network-vpn-disconnected-symbolic";
            toggle_action.set_state (new Variant.boolean (false));
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
                    toggle_action.set_state (new Variant.boolean (true));
                    break;
                case NM.VpnConnectionState.ACTIVATED:
                    toggle_button.icon_name = "panel-network-vpn-connected-symbolic";
                    toggle_action.set_state (new Variant.boolean (true));
                    break;
                case NM.VpnConnectionState.DISCONNECTED:
                    toggle_button.icon_name = "panel-network-vpn-disconnected-symbolic";
                    toggle_action.set_state (new Variant.boolean (false));
                    break;
                case NM.VpnConnectionState.FAILED:
                case NM.VpnConnectionState.UNKNOWN:
                    toggle_button.icon_name = "panel-network-vpn-error-symbolic";
                    toggle_action.set_state (new Variant.boolean (false));
                    break;
            }
        } else if (connection_type == NM.SettingWireGuard.SETTING_NAME) {
            switch (_vpn_connection.get_state ()) {
                case NM.ActiveConnectionState.UNKNOWN:
                    toggle_button.icon_name = "panel-network-vpn-error-symbolic";
                    toggle_action.set_state (new Variant.boolean (false));
                    break;
                case NM.ActiveConnectionState.DEACTIVATED:
                case NM.ActiveConnectionState.DEACTIVATING:
                    toggle_button.icon_name = "panel-network-vpn-disconnected-symbolic";
                    toggle_action.set_state (new Variant.boolean (false));
                    break;
                case NM.ActiveConnectionState.ACTIVATING:
                    toggle_button.icon_name = "panel-network-vpn-acquiring-symbolic";
                    toggle_action.set_state (new Variant.boolean (true));
                    break;
                case NM.ActiveConnectionState.ACTIVATED:
                    toggle_button.icon_name = "panel-network-vpn-connected-symbolic";
                    toggle_action.set_state (new Variant.boolean (true));
                    break;
            }
        }
    }
}
