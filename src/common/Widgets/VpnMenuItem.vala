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

public class Network.VpnMenuItem : Gtk.ListBoxRow {
    // A shared list between all vpn connections menu itens
    private static List<NM.RemoteConnection> item_list;

    public signal void user_action ();
    public NM.RemoteConnection? connection = null;
    public string id {
        get {
            return vpn.get_id ();
        }
    }
    public Network.State vpn_state { get; set; default = Network.State.DISCONNECTED; }

    Gtk.RadioButton radio_button;
    Gtk.Spinner spinner;
    Gtk.Image error_img;

    public NM.RemoteConnection vpn { get; private set; }

    public VpnMenuItem (NM.RemoteConnection? _connection, VpnMenuItem? previous = null) {
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

        item_list = new List<NM.RemoteConnection>();

        add_vpn (connection);

        notify["vpn_state"].connect (update);
        radio_button.notify["active"].connect (update);

        add (main_box);
        get_style_context ().add_class ("menuitem");
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

#if PLUG_NETWORK
        if (show_icons) {
#endif
            hide_item (error_img);
            hide_item (spinner);
#if PLUG_NETWORK
        }
#endif
        switch (vpn_state) {
        case State.FAILED_VPN:
            show_item (error_img);
            break;
        case State.CONNECTING_VPN:
            show_item (spinner);
            if (!radio_button.active) {
                critical ("An access point is being connected but not active.");
            }
            break;
        }
    }

    public void hide_icons (bool show_remove_button = true) {
#if PLUG_NETWORK
        show_icons = false;
        hide_item (error_img);
        hide_item (spinner);
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
        item_list.append (vpn);
        update ();
    }

    public bool remove_vpn (NM.RemoteConnection vpn) {
        item_list.remove (vpn);
        return item_list.length () > 0;
    }
}
