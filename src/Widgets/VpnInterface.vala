/*
* SPDX-License-Identifier: LGPL-2.1-or-later
* SPDX-FileCopyrightText: 2017-2023 elementary, Inc. (https://elementary.io)
*/

public class Network.VpnInterface : Network.WidgetNMInterface {
    public NM.Client nm_client { get; construct; }

    private GLib.ListStore vpn_list;
    private Gtk.FlowBox flowbox;

    public VpnInterface (NM.Client nm_client) {
        Object (nm_client: nm_client);
    }

    construct {
        vpn_list = new GLib.ListStore (typeof (NM.RemoteConnection));

        flowbox = new Gtk.FlowBox () {
            column_spacing = 6,
            row_spacing = 12,
            homogeneous = true,
            margin_top = 6,
            margin_end = 12,
            margin_bottom = 6,
            margin_start = 12,
            max_children_per_line = 3,
            selection_mode = Gtk.SelectionMode.NONE
        };
        flowbox.bind_model (vpn_list, create_widget_func);

        append (flowbox);

        nm_client.get_connections ().foreach ((connection) => vpn_added_cb (connection));
        nm_client.get_active_connections ().foreach ((connection) => active_connected_added_cb (connection));

        check_vpn_availability ();

        vpn_list.items_changed.connect (check_vpn_availability);

        nm_client.connection_added.connect (vpn_added_cb);
        nm_client.connection_removed.connect (vpn_removed_cb);

        nm_client.active_connection_added.connect (active_connected_added_cb);
        nm_client.active_connection_removed.connect (active_connected_removed_cb);

        flowbox.child_activated.connect ((child) => {
            vpn_activate_cb ((VpnMenuItem) child);
        });
    }

    private Gtk.Widget create_widget_func (Object object) {
        return new VpnMenuItem ((NM.RemoteConnection) object);
    }

    private void check_vpn_availability () {
        show_vpn (vpn_list.n_items > 0);
    }

    private void show_vpn (bool show) {
        visible = sep.visible = show;
    }

    private void active_connected_added_cb (NM.ActiveConnection active_connection) {
        unowned string connection_type = active_connection.get_connection_type ();
        if (connection_type != NM.SettingVpn.SETTING_NAME && connection_type != NM.SettingWireGuard.SETTING_NAME) {
            return;
        }

        var menu_item = get_item_for_active_connection (active_connection);
        if (menu_item != null) {
            menu_item.vpn_connection = active_connection;
        }
    }

    private void active_connected_removed_cb (NM.ActiveConnection active_connection) {
        var menu_item = get_item_for_active_connection (active_connection);
        if (menu_item != null) {
            menu_item.vpn_connection = null;
        }
    }

    private void vpn_activate_cb (VpnMenuItem item) {
        if (item.cancellable != null) {
            item.cancellable.cancel ();
        }

        item.cancellable = new Cancellable ();

        if (item.vpn_connection != null && item.vpn_connection.get_state () == NM.ActiveConnectionState.ACTIVATED) {
            nm_client.deactivate_connection_async.begin (item.vpn_connection, item.cancellable, (obj, res) => {
                try {
                    ((NM.Client) obj).deactivate_connection_async.end (res);
                    item.cancellable = null;
                } catch (Error e) {
                    critical ("Unable to deactivate VPN or Wireguard: %s", e.message);
                }
            });
        } else {
            nm_client.activate_connection_async.begin (item.remote_connection, null, null, item.cancellable, (obj, res) => {
                try {
                    ((NM.Client) obj).activate_connection_async.end (res);
                    item.cancellable = null;
                } catch (Error e) {
                    critical ("Unable to activate VPN or Wireguard: %s", e.message);
                }
            });
        }
    }

    private void vpn_added_cb (Object obj) {
        var remote_connection = (NM.RemoteConnection) obj;
        unowned string connection_type = remote_connection.get_connection_type ();
        if (connection_type == NM.SettingVpn.SETTING_NAME || connection_type == NM.SettingWireGuard.SETTING_NAME) {
            vpn_list.append (remote_connection);
        }
    }

    private void vpn_removed_cb (NM.RemoteConnection connection) {
        uint pos = -1;
        if (vpn_list.find (connection, out pos)) {
            vpn_list.remove (pos);
        }
    }

    private VpnMenuItem? get_item_for_active_connection (NM.ActiveConnection active_connection) {
        for (int i = 0; flowbox.get_child_at_index (i) != null; i++) {
            var menu_item = (VpnMenuItem) flowbox.get_child_at_index (i);
            if (menu_item.remote_connection == active_connection.connection) {
                return menu_item;
            }
        }

        return null;
    }
}
