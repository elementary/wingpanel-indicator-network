/*
* SPDX-License-Identifier: LGPL-2.1-or-later
* SPDX-FileCopyrightText: 2017-2023 elementary, Inc. (https://elementary.io)
*/

public class Network.VpnInterface : Network.WidgetNMInterface {
    public NM.Client nm_client { get; construct; }

    private Gtk.FlowBox vpn_list;

    public VpnInterface (NM.Client nm_client) {
        Object (nm_client: nm_client);
    }

    construct {
        vpn_list = new Gtk.FlowBox () {
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

        add (vpn_list);

        nm_client.get_connections ().foreach ((connection) => vpn_added_cb (connection));
        nm_client.get_active_connections ().foreach ((connection) => active_connected_added_cb (connection));

        update ();

        vpn_list.add.connect (check_vpn_availability);
        vpn_list.remove.connect (check_vpn_availability);

        nm_client.connection_added.connect (vpn_added_cb);
        nm_client.connection_removed.connect (vpn_removed_cb);

        nm_client.active_connection_added.connect (active_connected_added_cb);
        nm_client.active_connection_removed.connect (active_connected_removed_cb);

        vpn_list.child_activated.connect ((child) => {
            vpn_activate_cb ((VpnMenuItem) child);
        });
    }

    public override void update () {
        check_vpn_availability ();
        base.update ();
    }

    private void check_vpn_availability () {
        show_vpn (vpn_list.get_children ().length () > 0);
    }

    private void show_vpn (bool show) {
        no_show_all = sep.no_show_all = !show;
        visible = sep.visible = show;
    }

    private void active_connected_added_cb (NM.ActiveConnection active_connection) {
        if (!active_connection.vpn) {
            return;
        }

        var menu_item = get_item_for_active_connection (active_connection);
        if (menu_item != null) {
            menu_item.vpn_connection = (NM.VpnConnection) active_connection;
        }
    }

    private void active_connected_removed_cb (NM.ActiveConnection active_connection) {
        var menu_item = get_item_for_active_connection (active_connection);
        if (menu_item != null) {
            menu_item.vpn_connection = null;
        }
    }

    private void vpn_activate_cb (VpnMenuItem item) {
        if (item.vpn_connection != null) {
            nm_client.deactivate_connection_async.begin (item.vpn_connection, null, (obj, res) => {
                try {
                    ((NM.Client) obj).deactivate_connection_async.end (res);
                } catch (Error e) {
                    critical ("Unable to activate VPN: %s", e.message);
                }
            });
        } else {
            nm_client.activate_connection_async.begin (item.remote_connection, null, null, null, (obj, res) => {
                try {
                    ((NM.Client) obj).activate_connection_async.end (res);
                } catch (Error e) {
                    critical ("Unable to activate VPN: %s", e.message);
                }
            });
        }
    }

    private void vpn_added_cb (Object obj) {
        var remote_connection = (NM.RemoteConnection) obj;
        if (remote_connection.get_connection_type () == NM.SettingVpn.SETTING_NAME) {
            var item = new VpnMenuItem (remote_connection);
            vpn_list.add (item);
            update ();
        }
    }

    private void vpn_removed_cb (NM.RemoteConnection connection) {
        foreach (unowned var child in vpn_list.get_children ()) {
            unowned var menu_item = (VpnMenuItem) child;
            if (menu_item.remote_connection == connection) {
                menu_item.destroy ();
                update ();
                return;
            }
        }
    }

    private VpnMenuItem? get_item_for_active_connection (NM.ActiveConnection active_connection) {
        foreach (unowned var child in vpn_list.get_children ()) {
            unowned var menu_item = (VpnMenuItem) child;
            if (menu_item.remote_connection == active_connection.connection) {
                return menu_item;
            }
        }

        return null;
    }
}
