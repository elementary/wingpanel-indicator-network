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

public class Network.VpnInterface : Network.WidgetNMInterface {
    /**
     * If we want to add a visual feedback on DisplayWidget later,
     * we just need to remove vpn_state and swap it to state on the code
    **/
    public Network.State vpn_state { get; private set; default = Network.State.DISCONNECTED; }
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
            try {
                nm_client.deactivate_connection (item.vpn_connection);
            } catch (Error e) {
                critical (e.message);
            }
        } else {
            nm_client.activate_connection_async.begin (item.remote_connection, null, null, null, null);
        }

        Idle.add (() => {
            update ();
            return false;
        });
    }

    /**
      * The vpn_added_cb is called on new_connection signal,
      * (we get the vpn connections from there)
      * then we filter the connection that make sense for us.
    */
    private void vpn_added_cb (Object obj) {
        var remote_connection = (NM.RemoteConnection) obj;

        if (remote_connection.get_connection_type () == NM.SettingVpn.SETTING_NAME) {
            var item = new VpnMenuItem (remote_connection);
            vpn_list.add (item);
            update ();
        }
    }

    // Removed vpn, from removed signal attached to connection when it get added.
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
        var connection = active_connection.connection;
        foreach (unowned var child in vpn_list.get_children ()) {
            unowned var menu_item = (VpnMenuItem) child;
            if (menu_item.remote_connection == connection) {
                return menu_item;
            }
        }

        return null;
    }
}
