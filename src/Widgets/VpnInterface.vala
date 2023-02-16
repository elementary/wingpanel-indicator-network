/*
 * Copyright 2017-2021 elementary, Inc. (https://elementary.io)
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

    private NM.VpnConnection? active_vpn_connection = null;
    private Gtk.FlowBox vpn_list;

    private VpnMenuItem? active_vpn_item;
    private VpnMenuItem? blank_item = null;

    public VpnInterface (NM.Client nm_client) {
        Object (nm_client: nm_client);
    }

    construct {
        active_vpn_item = null;
        display_title = _("VPN");

        blank_item = new VpnMenuItem ();
        blank_item.no_show_all = true;

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

        update ();
        notify["vpn-state"].connect (update);

        vpn_list.add.connect (check_vpn_availability);
        vpn_list.remove.connect (check_vpn_availability);

        nm_client.notify["active-connections"].connect (update);
        nm_client.connection_added.connect (vpn_added_cb);
        nm_client.connection_removed.connect (vpn_removed_cb);

        nm_client.get_connections ().foreach ((connection) => vpn_added_cb (connection));

        vpn_list.child_activated.connect ((child) => {
            vpn_activate_cb ((VpnMenuItem) child);
        });
    }

    public override void update () {
        update_active_connection ();

        // VpnMenuItem? item = null;

        // if (active_vpn_connection != null) {
        //     switch (active_vpn_connection.vpn_state) {
        //         case NM.VpnConnectionState.UNKNOWN:
        //         case NM.VpnConnectionState.DISCONNECTED:
        //             vpn_state = State.DISCONNECTED;
        //             active_vpn_item = null;
        //             break;
        //         case NM.VpnConnectionState.PREPARE:
        //         case NM.VpnConnectionState.IP_CONFIG_GET:
        //         case NM.VpnConnectionState.CONNECT:
        //             vpn_state = State.CONNECTING_VPN;
        //             item = get_item_by_uuid (active_vpn_connection.get_uuid ());
        //             break;
        //         case NM.VpnConnectionState.FAILED:
        //             vpn_state = State.FAILED;
        //             active_vpn_item = null;
        //             break;
        //         case NM.VpnConnectionState.ACTIVATED:
        //             vpn_state = State.CONNECTED_VPN;
        //             item = get_item_by_uuid (active_vpn_connection.get_uuid ());
        //             sensitive = true;
        //             break;
        //         }
        // } else {
        //     vpn_state = State.DISCONNECTED;
        // }

        // if (item == null) {
        //     blank_item.set_active (true);

        //     if (active_vpn_item != null) {
        //         active_vpn_item.no_show_all = false;
        //         active_vpn_item.visible = true;
        //         active_vpn_item.vpn_state = vpn_state;
        //     }
        // }

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

    private void vpn_activate_cb (VpnMenuItem item) {
        nm_client.activate_connection_async.begin (item.connection, null, null, null, null);

        Idle.add (() => {
            update ();
            return false;
        });
    }

    private void vpn_deactivate_cb () {
        if (active_vpn_connection == null) {
            update ();
            return;
        }
        debug ("Deactivating VPN : %s", active_vpn_connection.get_id ());
        try {
            nm_client.deactivate_connection (active_vpn_connection);
        } catch (Error e) {
            warning (e.message);
        }
        Idle.add (() => { update (); return false; });
    }

    /**
      * The vpn_added_cb is called on new_connection signal,
      * (we get the vpn connections from there)
      * then we filter the connection that make sense for us.
    */
    private void vpn_added_cb (Object obj) {
        var vpn = (NM.RemoteConnection)obj;
        switch (vpn.get_connection_type ()) {
            case NM.SettingVpn.SETTING_NAME:
                // Add the item to vpn_list
                var item = new VpnMenuItem (vpn);
                vpn_list.add (item);
                update ();
                break;
            default:
                break;
        }
    }

    // Removed vpn, from removed signal attached to connection when it get added.
    private void vpn_removed_cb (NM.RemoteConnection vpn_) {
        // var item = get_item_by_uuid (vpn_.get_uuid ());
        // item.destroy ();
    }

    private VpnMenuItem? get_item_by_uuid (string uuid) {
        VpnMenuItem? item = null;
        foreach (unowned var child in vpn_list.get_children ()) {
            unowned var menu_item = (VpnMenuItem) child;
            if (menu_item.connection != null && menu_item.connection.get_uuid () == uuid && item == null) {
                item = (VpnMenuItem)child;
            }
        }

        return item;
    }

    /**
     * Loop through each active connection to find out the vpn.
    */
    private void update_active_connection () {
        active_vpn_connection = null;

        nm_client.get_active_connections ().foreach ((ac) => {
            if (ac.get_vpn () && active_vpn_connection == null) {
                active_vpn_connection = (NM.VpnConnection)ac;
                active_vpn_connection.vpn_state_changed.connect (update);

                foreach (unowned var child in vpn_list.get_children ()) {
                    unowned var menu_item = (VpnMenuItem) child;

                    if (menu_item.connection == null)
                        continue;

                    if (menu_item.connection.get_uuid () == active_vpn_connection.uuid) {
                        menu_item.set_active (true);
                        active_vpn_item = menu_item;
                        active_vpn_item.vpn_state = vpn_state;
                    } else {
                        menu_item.set_active (false);
                    }
                }
            }
        });
    }
}
