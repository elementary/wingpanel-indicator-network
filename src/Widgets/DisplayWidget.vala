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

public class Network.Widgets.DisplayWidget : Gtk.Box {
    private ListStore list_store;
    private NM.Client nm_client;

    construct {
        list_store = new ListStore (typeof (NM.Device));

        var flowbox = new Gtk.FlowBox () {
            column_spacing = 6,
            selection_mode = Gtk.SelectionMode.NONE
        };
        flowbox.bind_model (list_store, create_widget_func);

        add (flowbox);

        list_store.items_changed.connect (() => {
            flowbox.min_children_per_line = list_store.get_n_items ();
            flowbox.max_children_per_line = list_store.get_n_items () * 2;
            show_all ();
        });

        try {
            nm_client = new NM.Client ();
            foreach (unowned var device in nm_client.devices) {
                device_added_cb (device);
            }

            nm_client.device_added.connect (device_added_cb);
            nm_client.device_removed.connect (device_removed_cb);
        } catch (Error e) {
            critical (e.message);
        }
    }

    private void device_added_cb (NM.Device device) {
        switch (device.device_type) {
            case NM.DeviceType.ETHERNET:
            case NM.DeviceType.MODEM:
            case NM.DeviceType.WIFI:
            case NM.DeviceType.WIFI_P2P:
            case NM.DeviceType.WIMAX:
                list_store.append (device);
                break;
            default:
               break;
       }
    }

    private void device_removed_cb (NM.Device device) {
        uint pos = -1;
        list_store.find (device, out pos);
        if (pos != -1) {
            list_store.remove (pos);
        }
    }

    private Gtk.Widget create_widget_func (Object object) {
        var device = (NM.Device) object;

        var image = new Gtk.Image.from_icon_name (get_icon_name (device), Gtk.IconSize.MENU) {
            use_fallback = true
        };

        var revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT
        };
        revealer.add (image);

        switch (device.state) {
            case NM.DeviceState.DISCONNECTED:
            case NM.DeviceState.UNAVAILABLE:
                revealer.reveal_child = false;
                break;
            default:
                revealer.reveal_child = true;
                break;
        }

        device.state_changed.connect (() => {
            switch (device.state) {
                case NM.DeviceState.DISCONNECTED:
                case NM.DeviceState.UNAVAILABLE:
                    revealer.reveal_child = false;
                    break;
                default:
                    revealer.reveal_child = true;
                    break;
            }

            image.icon_name = get_icon_name (device);
        });

        return revealer;
    }

    private string get_icon_name (NM.Device device) {
        string icon_name = "network";

        switch (device.device_type) {
            case NM.DeviceType.ETHERNET:
                icon_name += "-wired";
                break;
            case NM.DeviceType.MODEM:
                icon_name += "-cellular";
                break;
            case NM.DeviceType.WIFI:
            case NM.DeviceType.WIMAX:
                icon_name += "-wireless";
                break;
            case NM.DeviceType.WIFI_P2P:
                icon_name += "-wireless-hotspot";
                break;
            default:
                break;
        }

        switch (device.state) {
            case NM.DeviceState.ACTIVATED:
                break;
            case NM.DeviceState.CONFIG:
            case NM.DeviceState.DEACTIVATING:
            case NM.DeviceState.PREPARE:
            case NM.DeviceState.IP_CONFIG:
            case NM.DeviceState.IP_CHECK:
                icon_name += "-acquiring";
                break;
            case NM.DeviceState.DISCONNECTED:
            case NM.DeviceState.UNAVAILABLE:
                icon_name += "-disconnected";
                break;
            case NM.DeviceState.FAILED:
                icon_name += "-error";
                break;
            case NM.DeviceState.NEED_AUTH:
            case NM.DeviceState.UNKNOWN:
            case NM.DeviceState.UNMANAGED:
                icon_name += "-no-route";
                break;
        }

        if (device.device_type == NM.DeviceType.WIFI) {
            var wifi_device = (NM.DeviceWifi) device;

            if (wifi_device.get_active_access_point () != null) {
                var strength = wifi_device.get_active_access_point ().get_strength ();

                if (strength < 30) {
                    icon_name += "-signal-weak";
                } else if (strength < 55) {
                    icon_name += "-signal-ok";
                } else if (strength < 80) {
                    icon_name += "-signal-good";
                } else {
                    icon_name += "-signal-excellent";
                }
            }
        }

        icon_name += "-symbolic";

        return icon_name;
    }
}
