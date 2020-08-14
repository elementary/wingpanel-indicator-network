/*
* Copyright 2015-2020 elementary, Inc. (https://elementary.io)
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

public class Network.WifiInterface : Network.AbstractWifiInterface {
    public bool hidden_sensitivity { get; set; default = true; }

    private Wingpanel.Widgets.Switch wifi_item;
    private Gtk.Revealer revealer;

    private Cancellable wifi_scan_cancellable = new Cancellable ();

    public WifiInterface (NM.Client nm_client, NM.Device? _device) {
        init_wifi_interface (nm_client, _device);

        wifi_item.caption = display_title;
        notify["display-title"].connect ( () => {
            wifi_item.caption = display_title;
        });

        wifi_item.notify["active"].connect (() => {
            var active = wifi_item.active;
            if (active != !software_locked) {
                rfkill.set_software_lock (RFKillDeviceType.WLAN, !active);
                nm_client.wireless_set_enabled (active);
            }
        });
    }

    construct {
        wifi_item = new Wingpanel.Widgets.Switch ("");
        wifi_item.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

        var scrolled_box = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            max_content_height = 512,
            propagate_natural_height = true
        };
        scrolled_box.add (wifi_list);

        revealer = new Gtk.Revealer ();
        revealer.add (scrolled_box);

        orientation = Gtk.Orientation.VERTICAL;
        pack_start (wifi_item);
        pack_start (revealer);
    }

    public override void update () {
        base.update ();

        wifi_item.set_sensitive (!hardware_locked);
        wifi_item.active = !locked;

        active_ap = wifi_device.get_active_access_point ();

        if (wifi_device.state == NM.DeviceState.UNAVAILABLE || state == Network.State.FAILED_WIFI) {
            revealer.reveal_child = false;
            hidden_sensitivity = false;
        } else {
            revealer.reveal_child = true;
            hidden_sensitivity = true;
        }
    }

    protected override void wifi_activate_cb (WifiMenuItem i) {
        var connections = nm_client.get_connections ();
        var device_connections = wifi_device.filter_connections (connections);
        var ap_connections = i.ap.filter_connections (device_connections);

        bool already_connected = ap_connections.length > 0;

        if (already_connected) {
            nm_client.activate_connection_async.begin (ap_connections.get (0),
                                                       wifi_device,
                                                       i.ap.get_path (),
                                                       null,
                                                       null);
        } else {
            debug ("Trying to connect to %s", NM.Utils.ssid_to_utf8 (i.ap.get_ssid ().get_data ()));

            if (i.ap.get_wpa_flags () == NM.@80211ApSecurityFlags.NONE) {
                debug ("Directly, as it is an insecure network.");
                nm_client.add_and_activate_connection_async.begin (NM.SimpleConnection.new (),
                                                                   device,
                                                                   i.ap.get_path (),
                                                                   null,
                                                                   null);
            } else {
                debug ("Needs a password or a certificate, let's open switchboard.");
                need_settings ();
            }
        }

        /* Do an update at the next iteration of the main loop, so as every
         * signal is flushed (for instance signals responsible for radio button
         * checked) */
        Idle.add (() => { update (); return false; });
    }

    public void start_scanning () {
        wifi_scan_cancellable.reset ();
        wifi_device.request_scan_async.begin (wifi_scan_cancellable, null);
    }

    public void cancel_scanning () {
        wifi_scan_cancellable.cancel ();
    }

    public void connect_to_hidden () {
        var hidden_dialog = new NMA.WifiDialog.for_other (nm_client);
        hidden_dialog.deletable = false;
        hidden_dialog.transient_for = (Gtk.Window) get_toplevel ();

        hidden_dialog.response.connect ((response) => {
            if (response == Gtk.ResponseType.OK) {
                NM.Connection? fuzzy = null;
                NM.Device dialog_device;
                NM.AccessPoint? dialog_ap = null;
                var dialog_connection = hidden_dialog.get_connection (out dialog_device, out dialog_ap);

                nm_client.get_connections ().foreach ((possible) => {
                    if (dialog_connection.compare (possible, NM.SettingCompareFlags.FUZZY | NM.SettingCompareFlags.IGNORE_ID)) {
                        fuzzy = possible;
                    }
                });

                string? path = null;
                if (dialog_ap != null) {
                    path = dialog_ap.get_path ();
                }

                if (fuzzy != null) {
                    nm_client.activate_connection_async.begin (fuzzy, wifi_device, path, null, null);
                } else {
                    var connection_setting = dialog_connection.get_setting (typeof (NM.Setting));

                    string? mode = null;
                    var setting_wireless = (NM.SettingWireless) dialog_connection.get_setting (typeof (NM.SettingWireless));
                    if (setting_wireless != null) {
                        mode = setting_wireless.get_mode ();
                    }

                    if (mode == "adhoc") {
                        if (connection_setting == null) {
                            connection_setting = new NM.SettingConnection ();
                        }

                        dialog_connection.add_setting (connection_setting);
                    }

                    nm_client.add_and_activate_connection_async.begin (dialog_connection,
                                                                       dialog_device,
                                                                       path,
                                                                       null,
                                                                       null);
                }
            }
        });

        hidden_dialog.run ();
        hidden_dialog.destroy ();
    }
}
