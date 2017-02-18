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
        // active_vpn_connection.notify["vpn_state"].connect (update);

        update ();
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
        critical ("Current vpn : %s, %s", active_vpn_connection.get_id (), active_vpn_connection.vpn_state.to_string ());
        if (active_vpn_connection.get_vpn()) {
            if (active_vpn_connection.vpn_state <= NM.VPNConnectionState.ACTIVATED) {
                critical ("Active vpn item %s", active_vpn_item.connection.get_id ());
                vpn_item.set_active (true);
            }
        }
        revealer.reveal_child = vpn_item.get_active ();

        base.update ();
    }

    protected override void vpn_activate_cb (VpnMenuItem item) {
        vpn_deactivate_cb ();

        debug ("Connecting to vpn : %s", item.connection.get_id());

        nm_client.activate_connection (item.connection, null, null, null);
        active_vpn_item = item;
        update ();
        // Idle.add (() => { update (); return false; });
    }

    protected override void vpn_deactivate_cb () {
        debug ("Deactivating vpn : %s", active_vpn_connection.get_id());
        if (active_vpn_connection == null) {
            return;
        }
        nm_client.deactivate_connection (active_vpn_connection);
        // TODO: Remove this
        critical ("VPN after %s", active_vpn_connection.get_id ());
    }
}
