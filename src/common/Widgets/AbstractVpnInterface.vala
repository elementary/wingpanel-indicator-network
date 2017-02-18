// TODO: Place a header

public abstract class Network.AbstractVpnInterface : Network.WidgetNMInterface {
    protected NM.VPNConnection? active_vpn_connection = null;

    protected Gtk.ListBox vpn_list;

    protected NM.Client nm_client;
    public NM.RemoteSettings nm_settings;

    protected VpnMenuItem? active_vpn_item { get; set; }
    protected VpnMenuItem? blank_item = null;
    protected Gtk.Stack placeholder;

    /** Overriding Network.WidgetNMInterface state,
    *   else it would mess with DisplayWidget icons.
    */
    protected Network.State state { get; set; default = Network.State.DISCONNECTED; }

    /* TODO:
     3: Show vpn list [x]
      3.1: Show vpn itens on vpn list [x]
     4: Connect vpns [x]
     5: Polish usability [x]
      5.1: User click [x]
      5.2: Spinner shows while connection get ready [x]
      5.3: User receive visual feedback [x](could be better)
     6: Cleanup
      6.1: Remove dead methods
     7: Check coding standards [x]
     7.1: Look the comments
     8: Complete any todo's and submit
    */
    public void init_vpn_interface (NM.Client _nm_client, NM.RemoteSettings _nm_settings) {
        nm_client = _nm_client;
        nm_settings = _nm_settings;
        display_title = _("Vpn");

        blank_item = new VpnMenuItem.blank ();
        active_vpn_item = null;

        /* Advices that no Vpn has been configured */
        var no_vpn_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        no_vpn_box.visible = true;
        no_vpn_box.valign = Gtk.Align.CENTER;

        var no_vpn = construct_placeholder_label (_("No Vpn Available"), true);
        no_vpn_box.add (no_vpn);

        var vpn_off_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        vpn_off_box.visible = true;
        vpn_off_box.valign = Gtk.Align.CENTER;

    #if PLUG_NETWORK
        var vpn_off = contruct_placeholder_label (_("Vpn is Disabled"), true);
        var vpn_off_desc = construct_placeholder_label (_("Enable Vpn to get a list with saved Vpn connections"));
        vpn_off_box.add (vpn_off);
        vpn_off_box.add (vpn_off_desc);
#endif
        placeholder.add_named (no_vpn_box, "no-vpn");
        placeholder.add_named (vpn_off_box, "vpn-off");
        placeholder.visible_child_name = "no-vpn";

        nm_settings.connections_read.connect (update);
        nm_client.notify["active-connections"].connect (update);
        nm_settings.new_connection.connect (vpn_added_cb);

        update ();
    }

    construct {
        placeholder = new Gtk.Stack ();
        placeholder.visible = true;

        vpn_list = new Gtk.ListBox ();
        vpn_list.activate_on_single_click = true;
        vpn_list.visible = true;
        vpn_list.set_placeholder (placeholder);
    }

    public override void update () {
        update_active_connection ();

        VpnMenuItem? item = null;

        if (active_vpn_connection != null){
            switch (active_vpn_connection.get_vpn_state ()) {
                case NM.VPNConnectionState.UNKNOWN:
                case NM.VPNConnectionState.DISCONNECTED:
                    state = State.DISCONNECTED;
                    if (active_vpn_item != null) {
                        item = get_item_by_uuid (active_vpn_connection.get_uuid ());
                        placeholder.visible_child_name = "vpn-off";
                    }
                    break;
                case NM.VPNConnectionState.PREPARE:
                case NM.VPNConnectionState.IP_CONFIG_GET:
                case NM.VPNConnectionState.CONNECT:
                    state = State.CONNECTING_VPN;
                    item = get_item_by_uuid (active_vpn_connection.get_uuid ());
                    break;
                case NM.VPNConnectionState.FAILED:
                    state = State.FAILED_VPN;
                    break;
                case NM.VPNConnectionState.ACTIVATED:
                    state = State.CONNECTED_VPN;
                    item = get_item_by_uuid (active_vpn_connection.get_uuid ());
                    sensitive = true;
                    break;
                }
        } else {
            state = State.DISCONNECTED;
        }

        if (item == null) {
            blank_item.set_active (true);

            if (active_vpn_item != null) {
                active_vpn_item.no_show_all = false;
                active_vpn_item.visible = true;
                active_vpn_item.state = state;
            }
        }

        base.update();
    }

    protected Gtk.Label construct_placeholder_label (string text, bool title = false) {
        var label = new Gtk.Label (text);
        label.visible = true;
        label.use_markup = true;
        label.wrap = true;
        label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        label.max_width_chars = 30;
        label.justify = Gtk.Justification.CENTER;

        if (title) {
#if PLUG_NETWORK
            label.get_style_context ().add_class ("h2");
#endif
        }

        return label;
    }

    void vpn_added_cb (Object obj) {
        var vpn = (NM.RemoteConnection)obj;
        switch (vpn.get_connection_type ()) {
            case NM.SettingVpn.SETTING_NAME:
                vpn.removed.connect(vpn_removed_cb);
                var item = new VpnMenuItem (vpn, get_previous_menu_item ());
                item.set_visible (true);
                item.user_action.connect (vpn_activate_cb);

                vpn_list.add (item);
                update ();
                break;
            default:
                break;
        }
    }

    void vpn_removed_cb (NM.RemoteConnection vpn_) {
        var item = get_item_by_uuid (vpn_.get_uuid ());
        item.destroy ();
    }

    private VpnMenuItem? get_item_by_uuid (string uuid) {
        VpnMenuItem? item = null;
        foreach (var child in vpn_list.get_children ()) {
            var _item = (VpnMenuItem)child;
            if (_item.connection != null && _item.connection.get_uuid () == uuid && item == null) {
                item = (VpnMenuItem)child;
            }
        }

        return item;
    }

    private VpnMenuItem? get_previous_menu_item () {
        var children = vpn_list.get_children ();
        if (children.length () == 0) {
            return blank_item;
        }

        return (VpnMenuItem)children.last ().data;
    }

    protected void update_active_connection () {
        active_vpn_connection = null;

        nm_client.get_active_connections ().foreach ((ac) => {
            if (ac.get_vpn () && active_vpn_connection == null) {
                active_vpn_connection = (NM.VPNConnection)ac;
                active_vpn_connection.vpn_state_changed.connect (update);

                foreach(var v in vpn_list.get_children()) {
                    var menu_item = (VpnMenuItem) v;

                    if (menu_item.connection.get_uuid () == active_vpn_connection.uuid) {
                        menu_item.set_active (true);
                        active_vpn_item = menu_item;
                        active_vpn_item.state = state;
                    }
                }
            }
        });
    }

    protected abstract void vpn_activate_cb (VpnMenuItem i);
    protected abstract void vpn_deactivate_cb ();
}
