/*-
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

public class Network.Widgets.WifiMenuItem : Gtk.RadioButton {
    private NM.AccessPoint _ap;
    public NM.AccessPoint ap
    {
        get { return _ap; }
        set
        {
            _ap = value;
            update ();
        }
    }

    public signal void wifi_activate(WifiMenuItem item);

    public WifiMenuItem (Gtk.RadioButton? radio = null) {
        if(radio != null) set_group(radio.get_group());
    }

    private void update ()
    {
        set_visible(_ap != null);

        if (ap == null)
            return;

        label = NM.Utils.ssid_to_utf8 (ap.get_ssid ());
        /*var icon_name = signal_strength_to_icon_name (ap.strength);

        if ((ap.flags & NM.@80211ApFlags.PRIVACY) != 0 || ap.wpa_flags != 0 || ap.rsn_flags != 0)
            icon_name += "-secure";

        property_set (Dbusmenu.MENUITEM_PROP_ICON_NAME, icon_name);*/

        clicked.connect( () => { wifi_activate (this); });
    }
}

public class Network.Widgets.PopoverWidget : Gtk.Box {
    private RFKillManager rfkill;
    private bool updating_rfkill = false;
    private NM.Client nm_client;
    private NM.RemoteSettings nm_settings;
    private NM.DeviceWifi? wifi_device;
    private NM.AccessPoint? active_ap;
    NM.Device? ethernet_device = null;

    private Wingpanel.Widgets.IndicatorSwitch wifi_item;
    private Wingpanel.Widgets.IndicatorSwitch ethernet_item;

    Gtk.Box wifi_list;

    private int frame_number = 0;
    private uint animate_timeout = 0;

    private const string SETTINGS_EXEC = "/usr/bin/switchboard network";

    private Wingpanel.Widgets.IndicatorSwitch show_percent_switch;

    private Wingpanel.Widgets.IndicatorButton show_settings_button;

    public signal void settings_shown ();

    public PopoverWidget () {
        Object (orientation: Gtk.Orientation.VERTICAL);

        build_ui ();
        connect_signals ();
        show_all();
    }

    private void build_ui () {

        // FIXME: Support more than one ethernet item
        ethernet_item = new Wingpanel.Widgets.IndicatorSwitch (_("Wired Connection"));
        this.pack_start (ethernet_item);
        this.pack_start (new Wingpanel.Widgets.IndicatorSeparator ());

        wifi_item = new Wingpanel.Widgets.IndicatorSwitch (_("Wi-Fi"));
        wifi_item.activate.connect (() =>
        {
            if (updating_rfkill)
                return;
            var active = wifi_item.get_active();
            rfkill.set_software_lock (RFKillDeviceType.WLAN, !active);
        });

        this.pack_start (wifi_item);

        var scrolled_window = new Gtk.ScrolledWindow(null, null);
        scrolled_window.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.NEVER);

        wifi_list = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);


        scrolled_window.add_with_viewport(wifi_list);

        this.pack_start(scrolled_window);

        this.pack_start (new Wingpanel.Widgets.IndicatorSeparator ());


        /* Monitor killswitch status */
        rfkill = new RFKillManager ();
        rfkill.open ();
        rfkill.device_added.connect (update_wifi_cb);
        rfkill.device_changed.connect (update_wifi_cb);
        rfkill.device_deleted.connect (update_wifi_cb);

        /* Monitor network manager */
        nm_client = new NM.Client ();
        nm_settings = new NM.RemoteSettings (null);

        nm_client.device_added.connect (device_added_cb);
        var devices = nm_client.get_devices ();
        for (var i = 0; i < devices.length; i++)
            device_added_cb (devices.get (i));

        show_settings_button = new Wingpanel.Widgets.IndicatorButton (_("Network Settings") + "…");

        this.pack_start (show_settings_button);

        update_wifi_cb();
    }

    private void device_added_cb (NM.Device device)
    {
        if (device is NM.DeviceWifi)
        {
            wifi_device = device as NM.DeviceWifi;
            wifi_device.notify["active-access-point"].connect (() => { update_wifi_cb (); });
            wifi_device.access_point_added.connect (update_wifi_cb);
            wifi_device.access_point_removed.connect (update_wifi_cb);
            wifi_device.state_changed.connect (update_wifi_cb);
        }
        else if (device is NM.DeviceEthernet)
        {
            ethernet_device = device;
            device.state_changed.connect(() => { update_wifi_cb(); });
        }
        else
            stderr.printf ("Unknown device: %s\n", device.get_device_type().to_string());
        update_wifi_cb ();
    }

    private void update_wifi_cb ()
    {
        /* Ethernet */
        bool ethernet_available = ethernet_device != null && ethernet_device.get_state() == NM.DeviceState.ACTIVATED;
        ethernet_item.set_active(ethernet_available);

        /* Wifi */
        var have_lock = false;
        var software_locked = false;
        var hardware_locked = false;
        foreach (var device in rfkill.get_devices ())
        {
            if (device.device_type != RFKillDeviceType.WLAN)
                continue;

            have_lock = true;
            if (device.software_lock)
                software_locked = true;
            if (device.hardware_lock)
                hardware_locked = true;
        }
        var locked = hardware_locked || software_locked;

        updating_rfkill = true;
        wifi_item.set_sensitive(!hardware_locked);
        wifi_item.set_active(!locked);
        updating_rfkill = false;

        var animate = false;

        wifi_list.forall( (w) => {
            w.destroy();
        });

        if (locked)
        {
            //network_service._icon_name = "nm-no-connection";

        }
        else
        {
            switch (wifi_device.state)
            {
            case NM.DeviceState.PREPARE:
                //network_service._icon_name = "nm-stage01-connecting%02d".printf (frame_number + 1);
                animate = true;
                break;
            case NM.DeviceState.CONFIG:
            case NM.DeviceState.NEED_AUTH:
                //network_service._icon_name = "nm-stage02-connecting%02d".printf (frame_number + 1);
                animate = true;
                break;
            case NM.DeviceState.IP_CONFIG:
                //network_service._icon_name = "nm-stage03-connecting%02d".printf (frame_number + 1);
                animate = true;
                break;
            default:
                active_ap = wifi_device.get_active_access_point ();
       /*         if (active_ap != null)
                    network_service._icon_name = signal_strength_to_icon_name (active_ap.strength);
                else
                    network_service._icon_name = "nm-no-connection";*/
                break;
            }
        }


        // TODO: looks like a bad way to do it, isn't it?
        if (animate)
        {
            if (animate_timeout == 0)
                animate_timeout = Timeout.add (100, () =>
                {
                    frame_number = (frame_number + 1) % 11;
                    animate_timeout = 0;
                    update_wifi_cb ();
                    return false;
                });
        }
        else
        {
            frame_number = 0;
            if (animate_timeout != 0)
                Source.remove (animate_timeout);
        }

        active_ap = wifi_device.get_active_access_point ();

        // FIXME: Sort by known networks, signal strength

        var aps = wifi_device.get_access_points ();
        var n_aps = 0;
        if (aps != null)
            n_aps = aps.length;
        var n = 0;

        WifiMenuItem? previous_item = null;
        for (var i = 0; i < n_aps; i++)
        {
            var ap = aps.get (i);

            /* Ignore duplicate APs */
            // FIXME: Should show the AP with the best strength and highest security
            var duplicate = false;
            for (var j = 0; j < i; j++)
            {
                var ap2 = aps.get (j);
                if (NM.Utils.same_ssid (ap2.get_ssid (), ap.get_ssid (), true))
                {
                    duplicate = true;
                    break;
                }
            }
            if (duplicate)
                continue;

            /* Put the first N items into the menu, and any others into an overflow menu */
            WifiMenuItem item = new WifiMenuItem(previous_item);
            previous_item = item;
        /*    else
            {
                item = new WifiMenuItem();
                item.wifi_activate.connect (wifi_activate_cb);
                this.pack_start(item);
                //wifi_overflow_item.child_append (item);
            }*/
            item.set_visible(true);
            item.set_active(ap == active_ap);
            item.ap = ap;
            item.wifi_activate.connect (wifi_activate_cb);

            wifi_list.pack_end(item);
            wifi_list.show_all();
        }
        //wifi_overflow_item.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, n > wifi_items.length);

    }

    private void wifi_activate_cb (WifiMenuItem item)
    {
        var i = item;
        
        NM.Connection? connection = null;

        var connections = nm_settings.list_connections ();
        var device_connections = wifi_device.filter_connections (connections);
        var ap_connections = i.ap.filter_connections (device_connections);

        if (ap_connections.length () > 0)
            nm_client.activate_connection (ap_connections.nth_data (0), wifi_device, i.ap.get_path (), null);
        else
        {
            connection = new NM.Connection ();
            var s_con = new NM.SettingConnection ();
            s_con.set (NM.SettingConnection.UUID, NM.Utils.uuid_generate ());
            connection.add_setting (s_con);
            var s_wifi = new NM.SettingWireless ();
            s_wifi.set (NM.SettingWireless.SSID, i.ap.get_ssid (), NM.SettingWireless.SEC, NM.SettingWirelessSecurity.SETTING_NAME);
            connection.add_setting (s_wifi);
            var s_wsec = new NM.SettingWirelessSecurity ();
            s_wsec.set (NM.SettingWirelessSecurity.KEY_MGMT, "wpa-eap");
            connection.add_setting (s_wsec);
            var s_8021x = new NM.Setting8021x ();
            s_8021x.add_eap_method ("ttls");
            s_8021x.set (NM.Setting8021x.PHASE2_AUTH, "mschapv2");
            connection.add_setting (s_8021x);
            var dialog = new NMAWifiDialog (nm_client, nm_settings, connection, wifi_device, i.ap, false);
            dialog.response.connect (() =>
            {
                nm_client.add_and_activate_connection (new NM.Connection (), wifi_device, i.ap.get_path (), null); dialog.destroy ();
            });
            dialog.present ();
        }
    }

    private void connect_signals () {
        //Services.SettingsManager.get_default ().schema.bind ("show-percentage", show_percent_switch.get_switch (), "active", SettingsBindFlags.DEFAULT);

        show_settings_button.clicked.connect (show_settings);
    }

    private void show_settings () {
        var cmd = new Granite.Services.SimpleCommand ("/usr/bin", SETTINGS_EXEC);
        cmd.run ();

        settings_shown ();
    }
}
