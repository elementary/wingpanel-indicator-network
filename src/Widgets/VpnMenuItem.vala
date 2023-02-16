/*
 * Copyright 2017-2020 elementary, Inc. (https://elementary.io)
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

public class Network.VpnMenuItem : Gtk.FlowBoxChild {
    public Network.State vpn_state { get; set; default = Network.State.DISCONNECTED; }
    public NM.RemoteConnection connection { get; construct; }

    private Gtk.ToggleButton toggle_button;

    public string id {
        get {
            return connection.get_id ();
        }
    }

    private static Gtk.CssProvider provider;
    private bool checking_vpn_connectivity = false;
    private Gtk.Label label;

    public VpnMenuItem (NM.RemoteConnection connection) {
        Object (connection: connection);
    }

    static construct {
        provider = new Gtk.CssProvider ();
        provider.load_from_resource ("io/elementary/wingpanel/network/Indicator.css");
    }

    construct {
        toggle_button = new Gtk.ToggleButton () {
            halign = Gtk.Align.CENTER,
            image = new Gtk.Image.from_icon_name ("network-vpn-symbolic", Gtk.IconSize.MENU)
        };
        toggle_button.get_style_context ().add_class ("circular");
        toggle_button.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);


        label = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            max_width_chars = 16
        };
        label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3) {
            hexpand = true
        };
        box.add (toggle_button);
        box.add (label);

        can_focus = false;
        add (box);

        toggle_button.toggled.connect (() => {
            activate ();
        });

        update ();
        connection.changed.connect (update);
        notify["vpn-state"].connect (update);
    }

    private void update () {
        label.label = connection.get_id ();

        switch (vpn_state) {
            case State.FAILED:
                ((Gtk.Image) toggle_button.image).icon_name = "network-vpn-error-symbolic";
                break;
            case State.CONNECTING_VPN:
                ((Gtk.Image) toggle_button.image).icon_name = "network-vpn-acquiring-symbolic";
                check_vpn_connectivity.begin ();
                break;
            default:
                ((Gtk.Image) toggle_button.image).icon_name = "network-vpn-symbolic";
                break;
        }
    }

    public void set_active (bool active) {
        toggle_button.active = active;
    }

    private async void nap (uint interval, int priority = GLib.Priority.DEFAULT) {
      GLib.Timeout.add (interval, () => {
          nap.callback ();
          return false;
        }, priority);
        yield;
    }

    /**
    * Uses a timeout to check VPN connectivity
    **/
    private async void check_vpn_connectivity () {
        if (!checking_vpn_connectivity) {

            checking_vpn_connectivity = true;

            for (int i = 0; i < 20; i++) {
                if (vpn_state == State.CONNECTED_VPN) {
                    checking_vpn_connectivity = false;
                    return;
                }
                yield nap (500);
            }
        }
    }
}
