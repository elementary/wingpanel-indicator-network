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
 */

public class Network.WifiMenuItem : Gtk.ListBoxRow {
    public NM.AccessPoint ap { get; private set; }
    public NM.DeviceState state { get; set; default = NM.DeviceState.DISCONNECTED; }

    public GLib.Bytes ssid {
        get {
            return ap.get_ssid ();
        }
    }

    public uint8 strength {
        get {
            uint8 strength = 0;
            foreach (unowned var ap in ap_list) {
                strength = uint8.max (strength, ap.get_strength ());
            }
            return strength;
        }
    }

    public bool active {
        set {
            radio_button.active = value;
        }
    }

    private Gtk.Image error_img;
    private Gtk.Image img_strength;
    private Gtk.Image lock_img;
    private Gtk.Label label;
    private Gtk.CheckButton radio_button;
    private Gtk.Spinner spinner;
    private List<NM.AccessPoint> ap_list;

    public WifiMenuItem (NM.AccessPoint ap, Gtk.CheckButton blank_radio) {
        label = new Gtk.Label (null) {
            ellipsize = Pango.EllipsizeMode.MIDDLE
        };

        radio_button = new Gtk.CheckButton.from_widget (blank_radio) {
            hexpand = true
        };
        radio_button.add (label);

        img_strength = new Gtk.Image () {
            icon_size = Gtk.IconSize.MENU
        };

        lock_img = new Gtk.Image.from_icon_name ("channel-insecure-symbolic", Gtk.IconSize.MENU);

        error_img = new Gtk.Image.from_icon_name ("process-error-symbolic", Gtk.IconSize.MENU) {
            tooltip_text = _("Unable to connect")
        };

        spinner = new Gtk.Spinner ();

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.add (radio_button);
        box.add (spinner);
        box.add (error_img);
        box.add (lock_img);
        box.add (img_strength);

        add (box);

        ap_list = new List<NM.AccessPoint> ();

        /* Adding the access point triggers update */
        add_ap (ap);

        notify["state"].connect (update);

        // We can't use clicked because we get in a weird loop state
        radio_button.button_release_event.connect ((b, ev) => {
            activate ();
            return Gdk.EVENT_STOP;
        });
    }

    class construct {
        set_css_name (Gtk.STYLE_CLASS_MENUITEM);
    }

    private void update_ap () {
        uint8 strength = 0;
        foreach (unowned var acess_point in ap_list) {
            ap = strength > acess_point.get_strength () ? ap : acess_point;
            strength = uint8.max (strength, acess_point.get_strength ());
        }

        label.label = NM.Utils.ssid_to_utf8 (ap.get_ssid ().get_data ());

        var flags = ap.get_wpa_flags () | ap.get_rsn_flags ();
        var is_secured = false;
        if (NM.@80211ApSecurityFlags.GROUP_WEP40 in flags) {
            is_secured = true;
            tooltip_text = _("40/64-bit WEP encrypted");
        } else if (NM.@80211ApSecurityFlags.GROUP_WEP104 in flags) {
            is_secured = true;
            tooltip_text = _("104/128-bit WEP encrypted");
        } else if (NM.@80211ApSecurityFlags.KEY_MGMT_SAE in flags) {
            is_secured = true;
            tooltip_text = _("WPA3 encrypted");
        } else if (NM.@80211ApSecurityFlags.KEY_MGMT_PSK in flags) {
            is_secured = true;
            tooltip_text = _("WPA encrypted");
        } else if (NM.@80211ApSecurityFlags.KEY_MGMT_OWE in flags ||
                   NM.@80211ApSecurityFlags.KEY_MGMT_OWE_TM in flags) {
            is_secured = true;
            tooltip_text = _("Passwordless encrypted");
        } else if (flags != NM.@80211ApSecurityFlags.NONE) {
            is_secured = true;
            tooltip_text = _("Encrypted");
        } else {
            tooltip_text = _("Unsecured");
        }

        lock_img.visible = !is_secured;
        lock_img.no_show_all = !lock_img.visible;
    }

    private const string BASE_ICON_NAME = "panel-network-wireless-signal-%s-symbolic";
    private void update () {
        if (strength < 30) {
            img_strength.icon_name = BASE_ICON_NAME.printf ("weak");
        } else if (strength < 55) {
            img_strength.icon_name = BASE_ICON_NAME.printf ("ok");
        } else if (strength < 80) {
            img_strength.icon_name = BASE_ICON_NAME.printf ("good");
        } else {
            img_strength.icon_name = BASE_ICON_NAME.printf ("excellent");
        }

        error_img.no_show_all = true;
        error_img.visible = false;
        error_img.hide ();

        spinner.stop ();

        switch (state) {
            case NM.DeviceState.FAILED:
                error_img.no_show_all = false;
                error_img.visible = true;
                break;
            case NM.DeviceState.PREPARE:
            case NM.DeviceState.CONFIG:
            case NM.DeviceState.NEED_AUTH:
            case NM.DeviceState.IP_CONFIG:
            case NM.DeviceState.IP_CHECK:
            case NM.DeviceState.SECONDARIES:
                spinner.start ();
                if (!radio_button.active) {
                    critical ("An access point is being connected but not active.");
                }
                break;
            default:
                break;
        }
    }

    public void add_ap (NM.AccessPoint ap) {
        ap_list.append (ap);
        update_ap ();
        update ();
    }

    public bool remove_ap (NM.AccessPoint ap) {
        ap_list.remove (ap);
        update_ap ();
        return ap_list.length () > 0;
    }
}
