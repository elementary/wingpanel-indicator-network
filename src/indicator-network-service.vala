/*
 * Copyright (C) 2012 Canonical Ltd.
 * Author: Robert Ancell <robert.ancell@canonical.com>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class NetworkIndicator:Gtk.Widget
{
    private DBusConnection bus;
    private Indicator.Service indicator_service;
    private Dbusmenu.Server menu_server;
    private NetworkService network_service;
    private RFKillManager rfkill;
    private bool updating_rfkill = false;
    private NM.Client nm_client;
    private NM.RemoteSettings nm_settings;
    private NM.DeviceWifi? wifi_device;
    private NM.AccessPoint? active_ap;

    private Dbusmenu.Menuitem menu;
    private Dbusmenu.Menuitem wifi_item;
    private WifiMenuItem[] wifi_items;
    private Dbusmenu.Menuitem wifi_overflow_item;

    private int frame_number = 0;
    private uint animate_timeout = 0;

    public NetworkIndicator () throws Error
    {
        indicator_service = new Indicator.Service ("com.canonical.indicator.network");
        menu_server = new Dbusmenu.Server ("/com/canonical/indicator/network/menu");

        network_service = new NetworkService ();
        bus.register_object ("/com/canonical/indicator/network/service", network_service);

        menu = new Dbusmenu.Menuitem ();
        menu_server.set_root (menu);

        wifi_item = new Dbusmenu.Menuitem ();
        wifi_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Wi-Fi"));
        wifi_item.property_set (Dbusmenu.MENUITEM_PROP_TYPE, "x-canonical-switch");
        wifi_item.item_activated.connect (() =>
        {
            if (updating_rfkill)
                return;
            var active = wifi_item.property_get_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE) == Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED;
            rfkill.set_software_lock (RFKillDeviceType.WLAN, active);
        });
        menu.child_append (wifi_item);

        wifi_items = new WifiMenuItem[5];
        for (var i = 0; i < 5; i++)
        {
            wifi_items[i] = new WifiMenuItem ();
            wifi_items[i].item_activated.connect (wifi_activate_cb);
            menu.child_append (wifi_items[i]);
        }

        wifi_overflow_item = new Dbusmenu.Menuitem ();
        wifi_overflow_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("More Networks"));
        menu.child_append (wifi_overflow_item);

        var sep = new Dbusmenu.Menuitem ();
        sep.property_set (Dbusmenu.MENUITEM_PROP_TYPE, Dbusmenu.CLIENT_TYPES_SEPARATOR);
        menu.child_append (sep);

        // FIXME: Support more than one ethernet item
        var ethernet_status_item = new Dbusmenu.Menuitem ();
        ethernet_status_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Wired Connection"));
        ethernet_status_item.property_set (Dbusmenu.MENUITEM_PROP_TOGGLE_TYPE, Dbusmenu.MENUITEM_TOGGLE_RADIO);
        menu.child_append (ethernet_status_item);

        sep = new Dbusmenu.Menuitem ();
        sep.property_set (Dbusmenu.MENUITEM_PROP_TYPE, Dbusmenu.CLIENT_TYPES_SEPARATOR);
        menu.child_append (sep);

        var settings_item = new Dbusmenu.Menuitem ();
        settings_item.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Network Settings..."));
        settings_item.item_activated.connect (() => { Process.spawn_command_line_async ("gnome-control-center network"); });
        menu.child_append (settings_item);

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
            update_wifi_cb ();
        }
        else if (device is NM.DeviceEthernet)
        {
        }
        else
            stderr.printf ("Unknown device: %s\n", device.driver);
    }

    private void update_wifi_cb ()
    {
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
        wifi_item.property_set_bool (Dbusmenu.MENUITEM_PROP_ENABLED, !hardware_locked);
        wifi_item.property_set_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE, locked ? Dbusmenu.MENUITEM_TOGGLE_STATE_UNCHECKED : Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED);
        updating_rfkill = false;

        var animate = false;
        if (locked)
        {
            for (var i = 0; i < wifi_items.length; i++)
                wifi_items[i].ap = null;
            wifi_overflow_item.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, false);
            network_service._icon_name = "nm-no-connection";
        }
        else
        {
            switch (wifi_device.state)
            {
            case NM.DeviceState.PREPARE:
                network_service._icon_name = "nm-stage01-connecting%02d".printf (frame_number + 1);
                animate = true;
                break;
            case NM.DeviceState.CONFIG:
            case NM.DeviceState.NEED_AUTH:
                network_service._icon_name = "nm-stage02-connecting%02d".printf (frame_number + 1);
                animate = true;
                break;
            case NM.DeviceState.IP_CONFIG:
                network_service._icon_name = "nm-stage03-connecting%02d".printf (frame_number + 1);
                animate = true;
                break;
            default:
                active_ap = wifi_device.get_active_access_point ();
                if (active_ap != null)
                    network_service._icon_name = signal_strength_to_icon_name (active_ap.strength);
                else
                    network_service._icon_name = "nm-no-connection";
                break;
            }
        }

        var builder = new VariantBuilder (VariantType.ARRAY);
        builder.add ("{sv}", "IconName", new Variant.string (network_service._icon_name));
        try
        {
            var properties = new Variant ("(sa{sv}as)", "com.canonical.indicator.network.service", builder, null);
            bus.emit_signal (null,
                             "/com/canonical/indicator/network/service",
                             "org.freedesktop.DBus.Properties",
                             "PropertiesChanged",
                             properties);
        }
        catch (Error e)
        {
            warning ("Failed to emit signal: %s", e.message);
        }

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
            WifiMenuItem item;
            if (n < wifi_items.length)
                item = wifi_items[n];
            else
            {
                item = new WifiMenuItem ();
                item.item_activated.connect (wifi_activate_cb);
                wifi_overflow_item.child_append (item);
            }
            item.property_set_int (Dbusmenu.MENUITEM_PROP_TOGGLE_STATE, ap == active_ap ? Dbusmenu.MENUITEM_TOGGLE_STATE_CHECKED : Dbusmenu.MENUITEM_TOGGLE_STATE_UNCHECKED);
            item.ap = ap;
            n++;
        }
        for (; n < wifi_items.length; n++)
            wifi_items[n].ap = null;
        wifi_overflow_item.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, n > wifi_items.length);
    }

    private void wifi_activate_cb (Dbusmenu.Menuitem item, uint arg1)
    {
        var i = item as WifiMenuItem;
        
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
}

private class WifiMenuItem : Dbusmenu.Menuitem
{
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

    public WifiMenuItem ()
    {
        property_set (Dbusmenu.MENUITEM_PROP_TOGGLE_TYPE, Dbusmenu.MENUITEM_TOGGLE_RADIO);
    }

    private void update ()
    {
        property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, ap != null);

        if (ap == null)
            return;

        property_set (Dbusmenu.MENUITEM_PROP_LABEL, NM.Utils.ssid_to_utf8 (ap.get_ssid ()));
        var icon_name = signal_strength_to_icon_name (ap.strength);

        if ((ap.flags & NM.@80211ApFlags.PRIVACY) != 0 || ap.wpa_flags != 0 || ap.rsn_flags != 0)
            icon_name += "-secure";

        property_set (Dbusmenu.MENUITEM_PROP_ICON_NAME, icon_name);
    }
}

private string signal_strength_to_icon_name (uint8 strength)
{
    if (strength > 80)
        return "nm-signal-100";
    else if (strength > 55)
        return "nm-signal-75";
    else if (strength > 30)
        return "nm-signal-50";
    else if (strength > 5)
        return "nm-signal-25";
    else
        return "nm-signal-00";
}

public static int main (string[] args)
{
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALE_DIR);
    Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (GETTEXT_PACKAGE);

    var loop = new MainLoop ();

    NetworkIndicator indicator;
    try
    {
        indicator = new NetworkIndicator ();
    }
    catch (Error e)
    {
        warning ("Failed to start network indicator service: %s", e.message);
        return Posix.EXIT_FAILURE;
    }
    // FIXMEindicator.shutdown.connect (() => { loop.quit (); });

    loop.run ();

    indicator = null;

    return Posix.EXIT_SUCCESS;
}

[DBus (name = "com.canonical.indicator.network.service")]
private class NetworkService : Object
{
    internal string _icon_name = "nm-no-connection";
    public string icon_name
    {
        get { return _icon_name; }
    }
}
