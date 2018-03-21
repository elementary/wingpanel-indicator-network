/*
 * Copyright (c) 2017 elementary LLC. (http://launchpad.net/elementary)
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

public class Network.VpnInterface : Network.AbstractVpnInterface {
    private Wingpanel.Widgets.Switch vpn_item;
    Gtk.Revealer revealer;

    public VpnInterface (NM.Client nm_client) {
        init_vpn_interface (nm_client);
        vpn_item.set_caption (display_title);
        debug ("Starting VPN Interface");

        vpn_item.get_style_context ().add_class ("h4");
        vpn_item.switched.connect (() => {
            revealer.reveal_child = vpn_item.get_active ();
            if (!vpn_item.get_active ()) {
                vpn_deactivate_cb ();
            }
        });

        vpn_list.add.connect (check_vpn_availability);
        vpn_list.remove.connect (check_vpn_availability);

        notify["vpn_state"].connect (update);
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        vpn_item = new Wingpanel.Widgets.Switch ("");
        vpn_item.get_style_context ().add_class ("h4");
        pack_start (vpn_item);

        var scrolled_box = new Wingpanel.Widgets.AutomaticScrollBox (null, null);
        scrolled_box.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scrolled_box.add (vpn_list);

        revealer = new Gtk.Revealer ();
        revealer.add (scrolled_box);
        pack_start (revealer);
    }

    public override void update () {
        base.update ();

        check_vpn_availability ();
        if (active_vpn_item != null) {
            vpn_item.set_active (true);
        }
    }

    private void check_vpn_availability () {
        var length = vpn_list.get_children ().length ();
        // The first item is the blank item
        show_vpn (length > 1);
    }

    private void show_vpn (bool show) {
        no_show_all = sep.no_show_all = !show;
        visible = sep.visible = show;
    }

    protected override void vpn_activate_cb (VpnMenuItem item) {
        warning ("Activating connection");
        vpn_deactivate_cb ();

        debug ("Connecting to VPN : %s", item.connection.get_id ());

        nm_client.activate_connection_async.begin (item.connection, null, null, null, null);
        active_vpn_item = item;
        Idle.add (() => { update (); return false; });
    }

    protected override void vpn_deactivate_cb () {
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
}
