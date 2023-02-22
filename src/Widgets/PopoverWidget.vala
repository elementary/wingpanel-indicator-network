/*
* Copyright 2015-2021 elementary, Inc. (https://elementary.io)
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
*
*/

public class Network.Widgets.PopoverWidget : Gtk.Grid {
    public NM.Client nm_client { get; construct; }
    private NM.VpnConnection? active_vpn_connection = null;

    public GLib.List<WidgetNMInterface>? network_interface { get; private owned set; }

    public bool secure { private set; get; default = false; }
    public string? extra_info { private set; get; default = null; }
    public Network.State state { private set; get; default = Network.State.CONNECTING_WIRED; }

    private Gtk.FlowBox other_box;
    private Gtk.Box wifi_box;
    private Gtk.Box vpn_box;
    private Gtk.ModelButton hidden_item;
    private Gtk.Revealer toggle_revealer;

    public bool is_in_session { get; construct; }

    public signal void settings_shown ();

    public PopoverWidget (bool is_in_session) {
        Object (is_in_session: is_in_session);
    }

    construct {
        network_interface = new GLib.List<WidgetNMInterface> ();

        orientation = Gtk.Orientation.VERTICAL;

        other_box = new Gtk.FlowBox () {
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
        wifi_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        vpn_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        try {
            nm_client = new NM.Client ();
        } catch (Error e) {
            critical (e.message);
        }

        if (is_in_session) {
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("io/elementary/wingpanel/network/Indicator.css");

            var airplane_toggle = new Gtk.ToggleButton () {
                halign = Gtk.Align.CENTER,
                image = new Gtk.Image.from_icon_name ("airplane-mode-symbolic", Gtk.IconSize.MENU)
            };
            airplane_toggle.get_style_context ().add_class ("circular");
            airplane_toggle.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            var airplane_label = new Gtk.Label (_("Airplane Mode"));
            airplane_label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

            var airplane_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
            airplane_box.add (airplane_toggle);
            airplane_box.add (airplane_label);

            other_box.add (airplane_box);

            airplane_toggle.toggled.connect (() => {
                nm_client.dbus_set_property.begin (NM.DBUS_PATH, NM.DBUS_INTERFACE, "Enable", !airplane_toggle.active, -1, null);
            });

            if (!airplane_toggle.active && !nm_client.networking_get_enabled ()) {
                airplane_toggle.activate ();
            }
        }

        var other_sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_top = 3,
            margin_bottom = 3
        };

        var toggle_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        toggle_box.add (other_box);
        toggle_box.add (other_sep);

        toggle_revealer = new Gtk.Revealer ();
        toggle_revealer.add (toggle_box);

        add (toggle_revealer);
        add (vpn_box);
        add (wifi_box);

        if (is_in_session) {
            hidden_item = new Gtk.ModelButton ();
            hidden_item.text = _("Connect to Hidden Network…");
            hidden_item.no_show_all = true;

            var show_settings_button = new Gtk.ModelButton ();
            show_settings_button.text = _("Network Settings…");

            add (hidden_item);
            add (show_settings_button);

            show_settings_button.clicked.connect (show_settings);
        }

        var vpn_interface = new VpnInterface (nm_client);
        network_interface.append (vpn_interface);
        add_interface (vpn_interface);

        var devices = nm_client.get_devices ();
        for (var i = 0; i < devices.length; i++) {
            device_added_cb (devices.get (i));
        }

        toggle_revealer.reveal_child = other_box.get_children () != null;
        show_all ();
        update_vpn_connection ();

        hidden_item.clicked.connect (() => {
            bool found = false;
            foreach (unowned var iface in network_interface) {
                if (iface is WifiInterface && ((WifiInterface) iface).hidden_sensitivity && !found) {
                    ((WifiInterface) iface).connect_to_hidden ();
                    found = true;
                }
            }
        });

        /* Monitor network manager */
        nm_client.device_added.connect (device_added_cb);
        nm_client.device_removed.connect (device_removed_cb);
        nm_client.notify["active-connections"].connect (update_vpn_connection);
        nm_client.notify["networking-enabled"].connect (update_state);

        vpn_interface.notify["state"].connect (update_state);
    }

    private void add_interface (WidgetNMInterface widget_interface) {
        if (widget_interface is EtherInterface) {
            other_box.add (widget_interface);
            return;
        }

        var container_box = wifi_box;

        if (widget_interface is Network.WifiInterface) {
            container_box = wifi_box;
            hidden_item.no_show_all = false;
            hidden_item.show_all ();

            ((Network.WifiInterface) widget_interface).notify["hidden-sensitivity"].connect (() => {
                bool hidden_sensitivity = false;

                foreach (unowned var iface in network_interface) {
                    if (iface is WifiInterface) {
                        hidden_sensitivity = hidden_sensitivity || ((WifiInterface) iface ).hidden_sensitivity;
                    }

                    hidden_item.sensitive = hidden_sensitivity;
                }
            });
        }

        if (widget_interface is Network.VpnInterface) {
            container_box = vpn_box;
        }

        if (is_in_session && get_children ().length () > 0) {
            container_box.pack_end (widget_interface.sep);
        }

        container_box.pack_end (widget_interface);
    }

    public void opened () {
        foreach (unowned var iface in network_interface) {
            if (iface is WifiInterface) {
                ((WifiInterface) iface).start_scanning ();
            }
        }
    }

    public void closed () {
        foreach (unowned var iface in network_interface) {
            if (iface is WifiInterface) {
                ((WifiInterface) iface).cancel_scanning ();
            }
        }
    }

    private void show_settings () {
        if (is_in_session) {
            try {
                AppInfo.launch_default_for_uri ("settings://network", null);
            } catch (Error e) {
                warning ("Failed to open network settings: %s", e.message);
            }

            settings_shown ();
        }
    }

    private void device_removed_cb (NM.Device device) {
        foreach (var widget_interface in network_interface) {
            if (widget_interface.device == device) {
                network_interface.remove (widget_interface);

                unowned var parent = widget_interface.get_parent ();
                if (parent is Gtk.FlowBoxChild) {
                    parent.destroy ();
                }

                widget_interface.sep.destroy ();
                widget_interface.destroy ();
                break;
            }
        }

        toggle_revealer.reveal_child = other_box.get_children () != null;
        update_interfaces_names ();
        update_state ();
    }

    private void update_interfaces_names () {
        NM.Device[] devices = {};
        foreach (unowned var iface in network_interface) {
            devices += iface.device;
        }

        var names = NM.Device.disambiguate_names (devices);

        for (int i = 0; i < network_interface.length (); i++) {
            network_interface.nth_data (i).display_title = names[i];
        }
    }

    private void device_added_cb (NM.Device device) {
        if (device.get_iface ().has_prefix ("vmnet") ||
            device.get_iface ().has_prefix ("lo") ||
            device.get_iface ().has_prefix ("veth") ||
            device.get_iface ().has_prefix ("vboxnet")) {
            return;
        }

        WidgetNMInterface? widget_interface = null;

        if (device is NM.DeviceWifi) {
            widget_interface = new WifiInterface (nm_client, device);
            debug ("Wifi interface added");
        } else if (device is NM.DeviceEthernet) {
            widget_interface = new EtherInterface (nm_client, device);
            debug ("Wired interface added");
        } else if (device is NM.DeviceModem) {
            widget_interface = new ModemInterface (nm_client, device);
            debug ("Modem interface added");
        } else {
            debug ("Unknown device: %s\n", device.get_device_type ().to_string ());
        }

        if (widget_interface != null) {
            // Implementation call
            network_interface.append (widget_interface);
            add_interface (widget_interface);
            widget_interface.notify["state"].connect (update_state);
            widget_interface.notify["extra-info"].connect (update_state);

        }

        update_interfaces_names ();

        foreach (var inter in network_interface) {
            inter.update ();
        }

        toggle_revealer.reveal_child = other_box.get_children () != null;
        update_state ();
        show_all ();
    }

    private void update_state () {
        if (!nm_client.networking_get_enabled ()) {
            state = Network.State.DISCONNECTED_AIRPLANE_MODE;
        } else {
            var next_state = Network.State.DISCONNECTED;
            var best_score = int.MAX;

            foreach (var inter in network_interface) {
                var score = inter.state.get_priority ();

                if (score < best_score) {
                    next_state = inter.state;
                    best_score = score;
                    if (inter is Network.ModemInterface) {
                        extra_info = ((Network.ModemInterface) inter).extra_info;
                    }
                }
            }

            state = next_state;
        }
    }

    private void update_vpn_connection () {
        active_vpn_connection = null;

        nm_client.get_active_connections ().foreach ((ac) => {
            if (active_vpn_connection == null && ac.vpn) {
                active_vpn_connection = (NM.VpnConnection) ac;

                secure = active_vpn_connection.get_vpn_state () == NM.VpnConnectionState.ACTIVATED;
                active_vpn_connection.vpn_state_changed.connect (() => {
                    secure = active_vpn_connection.get_vpn_state () == NM.VpnConnectionState.ACTIVATED;
                });
            }
        });
    }
}
