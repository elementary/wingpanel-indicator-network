/*
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * SPDX-FileCopyrightText: 2015-2023 elementary, Inc. (https://elementary.io)
 */

public class Network.Widgets.DisplayWidget : Gtk.Box {
    private ListStore list_store;
    private NM.Client nm_client;

    construct {
        list_store = new ListStore (typeof (NM.Device));

        var flowbox = new Gtk.FlowBox () {
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

        switch (device.device_type) {
            case NM.DeviceType.ETHERNET:
                return new EthernetItem ((NM.DeviceEthernet) device);
            case NM.DeviceType.MODEM:
                return new ModemItem ((NM.DeviceModem) device);
            case NM.DeviceType.WIFI:
                return new WifiItem ((NM.DeviceWifi) device);
            default:
                return new Gtk.Label ("");
       }
    }

    private class EthernetItem : Gtk.Revealer {
        public NM.DeviceEthernet device { get; construct; }
        private Gtk.Image image;

        public EthernetItem (NM.DeviceEthernet device) {
            Object (device: device);
        }

        construct {
            image = new Gtk.Image () {
                margin_start = 3,
                margin_end = 3,
                pixel_size = 24
            };

            add (image);
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;

            update_state ();
            device.state_changed.connect (update_state);
        }

        private void update_state () {
            switch (device.state) {
                case NM.DeviceState.DISCONNECTED:
                case NM.DeviceState.NEED_AUTH:
                case NM.DeviceState.UNAVAILABLE:
                case NM.DeviceState.UNKNOWN:
                case NM.DeviceState.UNMANAGED:
                    reveal_child = false;
                    break;
                default:
                    reveal_child = true;
                    break;
            }

            image.icon_name = get_icon_name ();
        }

        private string get_icon_name () {
            string icon_name = "network-wired";

            switch (device.state) {
                case NM.DeviceState.ACTIVATED:
                    break;
                case NM.DeviceState.CONFIG:
                case NM.DeviceState.DEACTIVATING:
                case NM.DeviceState.IP_CHECK:
                case NM.DeviceState.IP_CONFIG:
                case NM.DeviceState.PREPARE:
                case NM.DeviceState.SECONDARIES:
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

            return icon_name += "-symbolic";
        }
    }

    private class ModemItem : Gtk.Revealer {
        public NM.DeviceModem device { get; construct; }
        private Gtk.Image image;

        public ModemItem (NM.DeviceModem device) {
            Object (device: device);
        }

        construct {
            image = new Gtk.Image () {
                margin_start = 3,
                margin_end = 3,
                pixel_size = 24
            };

            add (image);
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;

            update_state ();
            device.state_changed.connect (update_state);
        }

        private void update_state () {
            switch (device.state) {
                case NM.DeviceState.DISCONNECTED:
                case NM.DeviceState.UNAVAILABLE:
                    reveal_child = false;
                    break;
                default:
                    reveal_child = true;
                    break;
            }

            image.icon_name = get_icon_name ();
        }

        private string get_icon_name () {
            return "network-cellular-signal-excellent-symbolic";
        }
    }

    private class WifiItem : Gtk.Revealer {
        public NM.DeviceWifi device { get; construct; }
        private Gtk.Image image;
        private uint animation_timeout;
        private int animation_state = 0;

        public WifiItem (NM.DeviceWifi device) {
            Object (device: device);
        }

        construct {
            image = new Gtk.Image () {
                margin_start = 3,
                margin_end = 3,
                use_fallback = true
            };

            add (image);
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;

            update_state ();
            device.state_changed.connect (update_state);
            device.notify["active-access-point"].connect (update_state);
        }

        private void update_state () {
            if (animation_timeout > 0) {
                Source.remove (animation_timeout);
                animation_timeout = 0;
            }

            switch (device.state) {
                case NM.DeviceState.DISCONNECTED:
                case NM.DeviceState.UNAVAILABLE:
                    reveal_child = false;
                    break;
                case NM.DeviceState.CONFIG:
                case NM.DeviceState.DEACTIVATING:
                case NM.DeviceState.IP_CHECK:
                case NM.DeviceState.IP_CONFIG:
                case NM.DeviceState.NEED_AUTH:
                case NM.DeviceState.PREPARE:
                case NM.DeviceState.SECONDARIES:
                    animate_icon ();
                    reveal_child = true;
                    break;
                default:
                    image.icon_name = get_icon_name ();
                    reveal_child = true;
                    break;
            }
        }

        private void animate_icon () {
            animation_timeout = Timeout.add (300, () => {
                animation_state = (animation_state + 1) % 4;
                string strength = "";
                switch (animation_state) {
                    case 0:
                        strength = "weak";
                        break;
                    case 1:
                        strength = "ok";
                        break;
                    case 2:
                        strength = "good";
                        break;
                    case 3:
                        strength = "excellent";
                        break;
                }
                image.icon_name = "network-wireless-signal-%s-symbolic".printf (strength);
                return true;
            });
        }

        private string get_icon_name () {
            string icon_name = "network-wireless";

            switch (device.state) {
                case NM.DeviceState.DISCONNECTED:
                case NM.DeviceState.UNAVAILABLE:
                    icon_name += "-offline";
                    break;
                case NM.DeviceState.FAILED:
                    icon_name += "-error";
                    break;
                case NM.DeviceState.NEED_AUTH:
                case NM.DeviceState.UNKNOWN:
                case NM.DeviceState.UNMANAGED:
                    icon_name += "-no-route";
                    break;
                default:
                    break;
            }

            var active_access_point = device.get_active_access_point ();
            if (active_access_point != null) {
                var strength = active_access_point.get_strength ();

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

            return icon_name += "-symbolic";
        }
    }
}
