/*
 * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
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

    public VpnInterface (NM.Client nm_client, NM.RemoteSettings nm_settings) {
        init_vpn_interface (nm_client, nm_settings);
        vpn_item.set_caption (display_title);
        debug ("Starting Vpn Interface");

        vpn_item.get_style_context ().add_class ("h4");
        vpn_item.switched.connect (() => {
            revealer.reveal_child = vpn_item.get_active();
            if (!vpn_item.get_active ()) {
                vpn_deactivate_cb ();
            }
        });
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

        if (active_vpn_connection != null && active_vpn_connection is NM.VPNConnection) {
            vpn_item.set_active (true);
        }
        revealer.reveal_child = vpn_item.get_active ();
    }

    protected override void vpn_activate_cb (VpnMenuItem item) {
        vpn_deactivate_cb ();

        debug ("Connecting to vpn : %s", item.connection.get_id());

        nm_client.activate_connection (item.connection, null, null, null);
        active_vpn_item = item;
        update ();
    }

    protected override void vpn_deactivate_cb () {
        if (active_vpn_connection == null) {
            return;
        }
        debug ("Deactivating vpn : %s", active_vpn_connection.get_id());
        nm_client.deactivate_connection (active_vpn_connection);
    }
}
