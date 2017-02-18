// TODO: Put header

public class Network.VpnMenuItem : Gtk.ListBoxRow {
    private List<NM.RemoteConnection> _vpn;
    public signal void user_action ();
    public NM.RemoteConnection? connection = null;
    public string id {
        get {
            return _tmp_vpn.get_id ();
        }
    }
    public Network.State state { get; set; default = Network.State.DISCONNECTED; }

    Gtk.RadioButton radio_button;
    Gtk.Spinner spinner;
    Gtk.Image error_img;

    public NM.RemoteConnection vpn { get { return _tmp_vpn; } }
    NM.RemoteConnection _tmp_vpn;

    public VpnMenuItem (NM.RemoteConnection? _connection, VpnMenuItem? previous = null) {
        debug ("[VpnMenuItem] Got instantiated");

        connection = _connection;
        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        main_box.margin_start = main_box.margin_end = 6;
        radio_button = new Gtk.RadioButton (null);
        if (previous != null) radio_button.set_group (previous.get_group ());

        radio_button.button_release_event.connect ( (b, ev) => {
            user_action ();
            return false;
        });

        error_img = new Gtk.Image.from_icon_name ("process-error-symbolic", Gtk.IconSize.MENU);
        error_img.margin_start = 6;
        error_img.set_tooltip_text (_("This Virtual Private Network could not be connected to."));

        spinner = new Gtk.Spinner();
        spinner.start ();
        spinner.visible = false;
        spinner.no_show_all = !spinner.visible;

        main_box.pack_start (radio_button, true, true);
        main_box.pack_start (spinner, false, false);
        main_box.pack_start (error_img, false, false);

        _vpn = new List<NM.RemoteConnection>();

        add_vpn (connection);

        notify["state"].connect (update);
        // radio_button.notify["active"].connect (update);
        add (main_box);
        get_style_context ().add_class ("menuitem");

        connection.changed.connect (update);
        update ();
    }

    /**
     * Only used for an item which is not displayed: hacky way to have no radio button selected.
     **/
    public VpnMenuItem.blank () {
        radio_button = new Gtk.RadioButton(null);
    }

    private string get_service_type () {
        var setting_vpn = connection.get_setting_vpn ();
        string service_type = setting_vpn.get_service_type ();
        string[] arr = service_type.split (".");
        return arr[arr.length - 1];
    }

    unowned SList get_group () {
        return radio_button.get_group();
    }

    public void set_active (bool active) {
        radio_button.set_active (active);
    }

    private void update () {
        radio_button.label = connection.get_id ();

        switch (state) {
        case State.FAILED_VPN:
            show_item (error_img);
            hide_item (spinner);
            break;
        case State.CONNECTING_VPN:
            show_item (spinner);
            break;
        default:
            hide_icons ();
            break;
        }
    }

    public void hide_icons (bool show_remove_button = true) {
        hide_item (error_img);
        hide_item (spinner);
#if PLUG_NETWORK
        if (!show_remove_button) {
            hide_item (remove_button);
        }
#endif
    }
    void show_item (Gtk.Widget w) {
        w.visible = true;
        w.no_show_all = w.visible;
    }

    void hide_item (Gtk.Widget w) {
        w.visible = false;
        w.no_show_all = !w.visible;
        w.hide ();
    }

    public void set_connection (NM.RemoteConnection _connection) {
        connection = _connection;
        connection.changed.connect (update);
        update ();
    }

    public void add_vpn (NM.RemoteConnection? vpn) {
        _vpn.append (vpn);
        update ();
    }

    public bool remove_vpn (NM.RemoteConnection vpn) {
        _vpn.remove (vpn);
        return _vpn.length () > 0;
    }
}
