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

public class Network.WifiMenuItem : Gtk.RadioButton {
    private NM.AccessPoint _ap;
	public signal void user_action();
    public NM.AccessPoint ap {
        get {
            return _ap;
        }
        set {
            _ap = value;
            update ();
        }
    }

    public WifiMenuItem (Gtk.RadioButton? radio = null) {
        if (radio != null) set_group (radio.get_group ());
		this.button_release_event.connect ( (b, ev) => {
			user_action();
			return false;
		});
    }

    private void update () {
        set_visible (_ap != null);

        if (ap == null)
            return;

        label = NM.Utils.ssid_to_utf8 (ap.get_ssid ());
        /*var icon_name = signal_strength_to_icon_name (ap.strength);

        if ((ap.flags & NM.@80211ApFlags.PRIVACY) != 0 || ap.wpa_flags != 0 || ap.rsn_flags != 0)
            icon_name += "-secure";

        property_set (Dbusmenu.MENUITEM_PROP_ICON_NAME, icon_name);*/
    }
}

public enum Network.State {
	DISCONNECTED,
	CONNECTED_WIRED,
	CONNECTED_WIFI,
	CONNECTING_WIFI,
	CONNECTING_WIRED,
	FAILED_WIRED,
	FAILED_WIFI
}

public abstract class Network.WidgetInterface : Gtk.Box {
	public abstract void update ();

	public Network.State state { get; protected set; default = Network.State.DISCONNECTED; }

	public Wingpanel.Widgets.IndicatorSeparator? sep = null;
	protected NM.Device? device;

	public signal void show_dialog (Gtk.Widget w);

	public bool is_device (NM.Device device) {
		return device == this.device;
	}
}

public class Network.WifiInterface : Network.WidgetInterface {
    RFKillManager rfkill;
    bool updating_rfkill = false;
    NM.DeviceWifi? wifi_device;
    private NM.AccessPoint? active_ap;
    private Wingpanel.Widgets.IndicatorSwitch wifi_item;
    Gtk.ListBox wifi_list;
    private int frame_number = 0;
    private uint animate_timeout = 0;

    
	private NM.Client nm_client;
    private NM.RemoteSettings nm_settings;

	public WifiInterface(NM.Client nm_client, NM.RemoteSettings nm_settings, NM.Device? _device) {
		
		set_orientation(Gtk.Orientation.VERTICAL);

		this.nm_client = nm_client;
		this.nm_settings = nm_settings;
		device = _device;
		wifi_device = device as NM.DeviceWifi;
        
		wifi_item = new Wingpanel.Widgets.IndicatorSwitch (_("Wi-Fi"));
        wifi_item.get_style_context ().add_class ("h4");
        wifi_item.activate.connect (() => {
            if (updating_rfkill)
                return;
            var active = wifi_item.get_active ();
            rfkill.set_software_lock (RFKillDeviceType.WLAN, !active);
        });

        pack_start (wifi_item);
        
		var scrolled_window = new Gtk.ScrolledWindow (null, null);
        scrolled_window.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.NEVER);

        wifi_list = new Gtk.ListBox ();


        scrolled_window.add_with_viewport (wifi_list);

        pack_start (scrolled_window);
        
		/* Monitor killswitch status */
        rfkill = new RFKillManager ();
        rfkill.open ();
        rfkill.device_added.connect (update);
        rfkill.device_changed.connect (update);
        rfkill.device_deleted.connect (update);
            
		wifi_device.notify["active-access-point"].connect (() => { update (); });
		wifi_device.access_point_added.connect (update);
		wifi_device.access_point_removed.connect (update);
		wifi_device.state_changed.connect (update);

	}

    public override void update () {
        
		/* Wifi */
        var have_lock = false;
        var software_locked = false;
        var hardware_locked = false;
        foreach (var device in rfkill.get_devices ()) {
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
        wifi_item.set_sensitive (!hardware_locked);
        wifi_item.set_active (!locked);
        updating_rfkill = false;

        wifi_list.forall ( (w) => {
            w.destroy();
        });

		switch (wifi_device.state) {
		case NM.DeviceState.UNKNOWN:
		case NM.DeviceState.UNMANAGED:
		case NM.DeviceState.DEACTIVATING:
		case NM.DeviceState.FAILED:
			state = State.FAILED_WIFI;
			break;

		case NM.DeviceState.UNAVAILABLE:
		case NM.DeviceState.DISCONNECTED:
			state = State.DISCONNECTED;
			break;

		case NM.DeviceState.PREPARE:
		case NM.DeviceState.CONFIG:
		case NM.DeviceState.NEED_AUTH:
		case NM.DeviceState.IP_CONFIG:
		case NM.DeviceState.IP_CHECK:
		case NM.DeviceState.SECONDARIES:
			state = State.CONNECTING_WIFI;
			break;
		
		case NM.DeviceState.ACTIVATED:
			state = State.CONNECTED_WIFI;
			break;
		}

        active_ap = wifi_device.get_active_access_point ();

        // FIXME: Sort by known networks, signal strength

        var aps = wifi_device.get_access_points ();
        var n_aps = 0;
        if (aps != null)
            n_aps = aps.length;
        var n = 0;

        WifiMenuItem? previous_item = null;
        for (var i = 0; i < n_aps; i++) {
            var ap = aps.get (i);

            /* Ignore duplicate APs */
            // FIXME: Should show the AP with the best strength and highest security
            var duplicate = false;
            for (var j = 0; j < i; j++) {
                var ap2 = aps.get (j);
                if (NM.Utils.same_ssid (ap2.get_ssid (), ap.get_ssid (), true)) {
                    duplicate = true;
                    break;
                }
            }
            if (duplicate)
                continue;

			assert(ap is NM.AccessPoint);

            /* Put the first N items into the menu, and any others into an overflow menu */
            WifiMenuItem item = new WifiMenuItem(previous_item);
            previous_item = item;
            item.set_visible(true);
            item.set_active(NM.Utils.same_ssid (ap.get_ssid (), active_ap.get_ssid (), true));
            item.ap = ap;
            item.user_action.connect(wifi_activate_cb);

            wifi_list.add(item);
        }

    }

	private void wifi_activate_cb (Gtk.Button item) {
        var i = item as WifiMenuItem;
        
        NM.Connection? connection = null;

        var connections = nm_settings.list_connections ();
        var device_connections = wifi_device.filter_connections (connections);
        var ap_connections = i.ap.filter_connections (device_connections);

		bool already_connected = ap_connections.length () > 0;

        if (already_connected) {
            nm_client.activate_connection (ap_connections.nth_data (0), wifi_device, i.ap.get_path (), null);
        } else {
			var w = new Gtk.Label ("wwwww");
			show_dialog (w);
        /*    connection = new NM.Connection ();
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
            dialog.response.connect (() => {
                nm_client.add_and_activate_connection (new NM.Connection (), wifi_device, i.ap.get_path (), null); dialog.destroy ();
            });
            dialog.present ();*/
        }

		update ();
    }

}

public class Network.EtherInterface : Network.WidgetInterface {
    private Wingpanel.Widgets.IndicatorSwitch ethernet_item;

	public EtherInterface(NM.Client nm_client, NM.RemoteSettings nm_settings, NM.Device? _device) {
		device = _device;
        ethernet_item = new Wingpanel.Widgets.IndicatorSwitch (_("Wired Connection"));
        ethernet_item.get_style_context ().add_class ("h4");
        add (ethernet_item);
        
		device.state_changed.connect (() => { update (); });
	}
    
	public override void update () {
        /* Ethernet */
        bool ethernet_available = device.get_state () == NM.DeviceState.ACTIVATED;
        ethernet_item.set_active (ethernet_available);

		switch (device.get_state ()) {
		case NM.DeviceState.UNKNOWN:
		case NM.DeviceState.UNMANAGED:
		case NM.DeviceState.DEACTIVATING:
		case NM.DeviceState.FAILED:
			state = State.FAILED_WIRED;
			break;

		case NM.DeviceState.UNAVAILABLE:
		case NM.DeviceState.DISCONNECTED:
			state = State.DISCONNECTED;
			break;

		case NM.DeviceState.PREPARE:
		case NM.DeviceState.CONFIG:
		case NM.DeviceState.NEED_AUTH:
		case NM.DeviceState.IP_CONFIG:
		case NM.DeviceState.IP_CHECK:
		case NM.DeviceState.SECONDARIES:
			state = State.CONNECTING_WIRED;
			break;
		
		case NM.DeviceState.ACTIVATED:
			state = State.CONNECTED_WIRED;
			break;
		}
	}

}

public class Network.Widgets.PopoverWidget : Gtk.Stack {
    private NM.Client nm_client;
    private NM.RemoteSettings nm_settings;

	Gtk.VBox main_box;
	Gtk.VBox secondary_box;
	Gtk.Widget? secondary_widget = null;

	GLib.List<WidgetInterface>? network_interface;

	public Network.State state { private set; get; default = Network.State.CONNECTING_WIRED; }


    private const string SETTINGS_EXEC = "/usr/bin/switchboard network";

    private Wingpanel.Widgets.IndicatorButton show_settings_button;

    public signal void settings_shown ();

    public PopoverWidget () {
		network_interface = new GLib.List<WidgetInterface>();

        build_ui ();
        connect_signals ();
        show_all();
    }

    void build_ui () {
		
		main_box = new Gtk.VBox (false, 0);

		secondary_box = new Gtk.VBox (false, 0);

		var back_button = new Gtk.Button.with_label ("Networks");
		back_button.get_style_context().add_class("back-button");

		back_button.clicked.connect ( () => {
			set_visible_child (main_box);
		});

		var tmp_hbox = new Gtk.HBox(false, 5);
		tmp_hbox.pack_start(back_button, false, false);
		secondary_box.pack_start(tmp_hbox, false, false);
		secondary_box.pack_start (new Wingpanel.Widgets.IndicatorSeparator ());

		add (main_box);

		add (secondary_box);

		transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        show_settings_button = new Wingpanel.Widgets.IndicatorButton (_("Network Settings…"));
        main_box.pack_end (show_settings_button);


        /* Monitor network manager */
        nm_client = new NM.Client ();
        nm_settings = new NM.RemoteSettings (null);

        nm_client.device_added.connect (device_added_cb);
        nm_client.device_removed.connect (device_removed_cb);
        
		var devices = nm_client.get_devices ();
        for (var i = 0; i < devices.length; i++)
            device_added_cb (devices.get (i));
    }

    void device_removed_cb (NM.Device device) {
		foreach (var widget_interface in network_interface) {
			if (widget_interface.is_device (device)) {
				network_interface.remove (widget_interface);
				
				if (widget_interface.sep != null) {
					widget_interface.sep.destroy ();
				}

				widget_interface.destroy ();
				break;
			}
		}
	}

    private void device_added_cb (NM.Device device) {
		WidgetInterface? widget_interface = null;

        if (device is NM.DeviceWifi) {
			widget_interface = new WifiInterface (nm_client, nm_settings, device);
			debug ("Wifi interface added");
        } else if (device is NM.DeviceEthernet) {
			widget_interface = new EtherInterface (nm_client, nm_settings, device);
			debug ("Etherner interface added");
        } else {
            stderr.printf ("Unknown device: %s\n", device.get_device_type().to_string());
        }

		if (widget_interface != null) {
			widget_interface.sep = new Wingpanel.Widgets.IndicatorSeparator ();
			main_box.pack_end (widget_interface.sep);
			main_box.pack_end (widget_interface);
			network_interface.append (widget_interface);

			widget_interface.notify["state"].connect(update_state);

			widget_interface.show_dialog.connect (show_inplace_dialog);
		}

		update_all();

		show_all();
    }

	void show_inplace_dialog(Gtk.Widget w) {
		if (secondary_widget != null) {
			secondary_widget.destroy ();
		}
		secondary_widget = w;
		secondary_box.pack_end(w);

		secondary_box.show_all ();
		set_visible_child (secondary_box);
	}

	void update_all () {
		foreach(var inter in network_interface) {
			inter.update ();
		}
	}

	void update_state () {
		var next_state = Network.State.DISCONNECTED;
		foreach (var inter in network_interface) {
			if (inter.state != Network.State.DISCONNECTED) {
				next_state = inter.state;
			}
		}

		state = next_state;
	}

    private void connect_signals () {
        show_settings_button.clicked.connect (show_settings);
    }

    private void show_settings () {
        var cmd = new Granite.Services.SimpleCommand ("/usr/bin", SETTINGS_EXEC);
        cmd.run ();

        settings_shown ();
    }
}
