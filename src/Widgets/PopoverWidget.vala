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

public class Network.WifiMenuItem : Gtk.Box {
	private List<NM.AccessPoint> _ap;
	public signal void user_action();
	public GLib.ByteArray ssid {
		get {
			return _tmp_ap.get_ssid();
		}
	}

	public Network.State state { get; set; default=Network.State.DISCONNECTED; }

	public uint8 strength {
		get {
			uint8 strength = 0;
			foreach(var ap in _ap) {
				strength = uint8.max(strength, ap.get_strength());
			}
			return strength;
		}
	}

	public NM.AccessPoint ap { get { return _tmp_ap; } }
	NM.AccessPoint _tmp_ap;

	Gtk.RadioButton radio_button;
	Gtk.Image img_strength;
	Gtk.Image lock_img;
	Gtk.Image error_img;
	Gtk.Spinner spinner;

	public WifiMenuItem (NM.AccessPoint ap, WifiMenuItem? previous = null) {

		radio_button = new Gtk.RadioButton(null);
		radio_button.margin_start = 6;
		if (previous != null) radio_button.set_group (previous.get_group ());

		radio_button.button_release_event.connect ( (b, ev) => {
			user_action();
			return false;
		});

		img_strength = new Gtk.Image();
		img_strength.margin_end = 6;
		
		lock_img = new Gtk.Image.from_icon_name ("channel-secure-symbolic", Gtk.IconSize.MENU);
		lock_img.margin_start = 6;
		
		/* TODO: investigate this, it has not been tested yet. */
		error_img = new Gtk.Image.from_icon_name ("process-error-symbolic", Gtk.IconSize.MENU);
		error_img.margin_start = 6;

		error_img.set_tooltip_text (_("This wireless network could not be connected to."));
		
		pack_start(radio_button, true, true);
		spinner = new Gtk.Spinner();
		spinner.start();
		spinner.visible = false;
		spinner.no_show_all = !spinner.visible;
		pack_start(spinner, false, false);
		pack_start(error_img, false, false);
		pack_start(lock_img, false, false);
		pack_start(img_strength, false, false);
		
		_ap = new List<NM.AccessPoint>();

		/* Adding the access point triggers update */
		add_ap(ap);

		notify["state"].connect (update);
		radio_button.notify["active"].connect (update);
	}

	/**
	 * Only used for an item which is not displayed: hacky way to have no radio button selected.
	 **/
	public WifiMenuItem.blank () {
		radio_button = new Gtk.RadioButton(null);
	}

	void update_tmp_ap () {
		uint8 strength = 0;
		foreach(var ap in _ap) {
			_tmp_ap = strength > ap.get_strength () ? _tmp_ap : ap;
			strength = uint8.max (strength, ap.get_strength ());
		}
	}

	public void set_active (bool active) {
		radio_button.set_active (active);
	}

	unowned SList get_group () {
		return radio_button.get_group();
	}

	void set_lock_img_tooltip (NM.@80211ApSecurityFlags flags) {
		if((flags & NM.@80211ApSecurityFlags.GROUP_WEP40) != 0) {
			lock_img.set_tooltip_text(_("This network uses 40/64-bit WEP encryption."));
		}
		else if((flags & NM.@80211ApSecurityFlags.GROUP_WEP104) != 0) {
			lock_img.set_tooltip_text(_("This network uses 104/128-bit WEP encryption."));
		}
		else if((flags & NM.@80211ApSecurityFlags.KEY_MGMT_PSK) != 0)  {
			lock_img.set_tooltip_text(_("This network uses WPA encryption."));
		} else {
			lock_img.set_tooltip_text(_("This network uses encryption."));
		}
	}

	private void update () {
		radio_button.label = NM.Utils.ssid_to_utf8 (ap.get_ssid ());

		img_strength.set_from_icon_name("network-wireless-signal-" + strength_to_string(strength) + "-symbolic", Gtk.IconSize.MENU);
		img_strength.show_all();

		lock_img.visible = ap.get_wpa_flags () != NM.@80211ApSecurityFlags.NONE;
		set_lock_img_tooltip(ap.get_wpa_flags ());
		lock_img.no_show_all = !lock_img.visible;

		hide_item(error_img);
		hide_item(spinner);
		switch (state) {
		case State.FAILED_WIFI:
			show_item(error_img);
			break;
		case State.CONNECTING_WIFI:
			show_item(spinner);
			if(!radio_button.active) {
				critical("An access point is being connected but not active.");
			}
			break;
		}
	}

	void show_item(Gtk.Widget w) {
		w.visible = true;
		w.no_show_all = !w.visible;
	}

	void hide_item(Gtk.Widget w) {
		w.visible = false;
		w.no_show_all = !w.visible;
		w.hide();
	}

	public void add_ap(NM.AccessPoint ap) {
		_ap.append(ap);
		update_tmp_ap();

		update();
	}

	string strength_to_string(uint8 strength) {
		if(0 <= strength < 30)
			return "weak";
		else if(strength < 55)
			return "ok";
		else if(strength < 80)
			return "good";
		else
			return "excellent";
	}

	public bool remove_ap(NM.AccessPoint ap) {
		_ap.remove(ap);

		update_tmp_ap();

		return _ap.length() > 0;
	}


}

public enum Network.State {
	DISCONNECTED,
	CONNECTED_WIRED,
	CONNECTED_WIFI,
	CONNECTED_WIFI_WEAK,
	CONNECTED_WIFI_OK,
	CONNECTED_WIFI_GOOD,
	CONNECTED_WIFI_EXCELLENT,
	CONNECTING_WIFI,
	CONNECTING_WIRED,
	FAILED_WIRED,
	FAILED_WIFI
}

public abstract class Network.WidgetInterface : Gtk.Box {
	public abstract void update ();

	public Network.State state { get; protected set; default = Network.State.DISCONNECTED; }

	public Wingpanel.Widgets.Separator? sep = null;
	protected NM.Device? device;

	public signal void show_dialog (Gtk.Widget w);
	public signal void need_settings ();

	public bool is_device (NM.Device device) {
		return device == this.device;
	}
}

public class Network.WifiInterface : Network.WidgetInterface {
	RFKillManager rfkill;
	bool updating_rfkill = false;
	NM.DeviceWifi? wifi_device;
	private NM.AccessPoint? active_ap;
	private Wingpanel.Widgets.Switch wifi_item;
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
	
		blank_item = new WifiMenuItem.blank ();
		
		wifi_item = new Wingpanel.Widgets.Switch (_("Wi-Fi"));
		wifi_item.get_style_context ().add_class ("h4");
		wifi_item.switched.connect (() => {
			if (updating_rfkill)
				return;
			var active = wifi_item.get_active ();
			rfkill.set_software_lock (RFKillDeviceType.WLAN, !active);
		});

		pack_start (wifi_item);
		
		var scrolled_box = new AutomaticScrollBox (null, null);
		
		wifi_list = new Gtk.ListBox ();
		
		scrolled_box.add_with_viewport(wifi_list);

		pack_start (scrolled_box);
		
		/* Monitor killswitch status */
		rfkill = new RFKillManager ();
		rfkill.open ();
		rfkill.device_added.connect (update);
		rfkill.device_changed.connect (update);
		rfkill.device_deleted.connect (update);
			
		wifi_device.notify["active-access-point"].connect (() => { update (); });
		wifi_device.access_point_added.connect (access_point_added_cb);
		wifi_device.access_point_removed.connect (access_point_removed_cb);
		wifi_device.state_changed.connect (update);
		
		var aps = wifi_device.get_access_points ();
		aps.foreach(access_point_added_cb);

		update();


	}

	WifiMenuItem? active_wifi_item = null;
	WifiMenuItem? blank_item = null;
	void access_point_added_cb (Object ap_) {
		NM.AccessPoint ap = (NM.AccessPoint)ap_;
		WifiMenuItem? previous_wifi_item = blank_item;

		bool found = false;

		foreach(var w in wifi_list.get_children()) {
			var menu_item = (WifiMenuItem) ((Gtk.Bin)w).get_child();

			if(NM.Utils.same_ssid (ap.get_ssid (), menu_item.ssid, true)) {
				found = true;
				menu_item.add_ap(ap);
				break;
			}

			previous_wifi_item = menu_item;
		}

		/* Sometimes network manager sends a (fake?) AP without a valid ssid. */
		if(!found && ap.get_ssid() != null) {
			WifiMenuItem item = new WifiMenuItem(ap, previous_wifi_item);

			var row = new Gtk.ListBoxRow ();

			row.add (item);
			row.get_style_context ().add_class ("menuitem");

			previous_wifi_item = item;
			item.set_visible(true);
			item.user_action.connect(wifi_activate_cb);

			wifi_list.add (row);

			wifi_list.show_all ();

			update_active_ap ();
		}

	}

	void update_active_ap () {

		debug("Update active AP");
		
		active_ap = wifi_device.get_active_access_point ();
		
		if (active_wifi_item != null) {
			if(active_wifi_item.state == Network.State.CONNECTING_WIFI) {
				active_wifi_item.state = Network.State.DISCONNECTED;
			}
			active_wifi_item = null;
		}

		if(active_ap == null) {
			debug("No active AP");
			blank_item.set_active (true);
		}
		else {
			debug("Active ap: %s", NM.Utils.ssid_to_utf8(active_ap.get_ssid()));
			
			bool found = false;
			foreach(var w in wifi_list.get_children()) {
				var menu_item = (WifiMenuItem) ((Gtk.Bin)w).get_child();

				if(NM.Utils.same_ssid (active_ap.get_ssid (), menu_item.ssid, true)) {
					found = true;
					menu_item.set_active (true);
					active_wifi_item = menu_item;
					active_wifi_item.state = state;
				}
			}

			if (!found) {
				critical ("Active AP not added");
			}
		}
	}
	
	void clean_failed_items () {
		foreach(var w in wifi_list.get_children()) {
			var menu_item = (WifiMenuItem) ((Gtk.Bin)w).get_child();
			menu_item.state = Network.State.DISCONNECTED;
		}
	}
	
	void access_point_removed_cb (Object ap_) {
		NM.AccessPoint ap = (NM.AccessPoint)ap_;

		WifiMenuItem found_item = null;

		foreach(var w in wifi_list.get_children()) {
			var menu_item = (WifiMenuItem) ((Gtk.Bin)w).get_child();

			assert(menu_item != null);

			if(NM.Utils.same_ssid (ap.get_ssid (), menu_item.ssid, true)) {
				found_item = menu_item;
				break;
			}
		}

		if(found_item == null) {
			critical("Couldn't remove an access point which has not been added.");
		}
		else {
			if(!found_item.remove_ap(ap)) {
				found_item.get_parent().destroy ();
			}
		}

		update_active_ap ();

	}

	Network.State strength_to_state (uint8 strength) {
		if(0 <= strength < 30)
			return Network.State.CONNECTED_WIFI_WEAK;
		else if(strength < 55)
			return Network.State.CONNECTED_WIFI_OK;
		else if(strength < 80)
			return Network.State.CONNECTED_WIFI_GOOD;
		else
			return Network.State.CONNECTED_WIFI_EXCELLENT;
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

		active_ap = wifi_device.get_active_access_point ();

		switch (wifi_device.state) {
		case NM.DeviceState.UNKNOWN:
		case NM.DeviceState.UNMANAGED:
		case NM.DeviceState.DEACTIVATING:
		case NM.DeviceState.FAILED:
			state = State.FAILED_WIFI;
			if(active_wifi_item != null) {
				active_wifi_item.state = state;
			}
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
			state = strength_to_state(active_ap.get_strength());
			break;
		}

		debug("New network state: %s", state.to_string ());

		update_active_ap ();
	}

	private void wifi_activate_cb (WifiMenuItem i) {
		NM.Connection? connection = null;

		var connections = nm_settings.list_connections ();
		var device_connections = wifi_device.filter_connections (connections);
		var ap_connections = i.ap.filter_connections (device_connections);

		bool already_connected = ap_connections.length () > 0;

		if (already_connected) {
			nm_client.activate_connection (ap_connections.nth_data (0), wifi_device, i.ap.get_path (), null);
		} else {
			debug("Trying to connect to %s", NM.Utils.ssid_to_utf8(i.ap.get_ssid()));
			if(i.ap.get_wpa_flags () == NM.@80211ApSecurityFlags.NONE) {
				debug("Directly, as it is an insecure network.");
				nm_client.add_and_activate_connection (new NM.Connection (), device, i.ap.get_path (), null);
			}
			else {
				debug("Needs a password or a certificate, let's open switchboard.");
				need_settings ();
			}
		/*	connection = new NM.Connection ();
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

		/* Do an update at the next iteration of the main loop, so as every
		 * signal is flushed (for instance signals responsible for radio button
		 * checked) */
		Idle.add( () => { update (); return false; });
	}

}

public class Network.EtherInterface : Network.WidgetInterface {
	private Wingpanel.Widgets.Switch ethernet_item;

	public EtherInterface(NM.Client nm_client, NM.RemoteSettings nm_settings, NM.Device? _device) {
		device = _device;
		ethernet_item = new Wingpanel.Widgets.Switch (_("Wired"));
		ethernet_item.get_style_context ().add_class ("h4");
		ethernet_item.switched.connect( () => {
			debug("update");
			if(ethernet_item.get_active()) {
				device.set_autoconnect(true);
			}
			else {
				device.disconnect(() => { debug("Successfully disconnected."); });
			}
		});
		add (ethernet_item);
		
		device.state_changed.connect (() => { update (); });
	}
	
	public override void update () {

		switch (device.get_state ()) {
		case NM.DeviceState.UNKNOWN:
		case NM.DeviceState.UNMANAGED:
		case NM.DeviceState.DEACTIVATING:
		case NM.DeviceState.FAILED:
			ethernet_item.sensitive = false;
			ethernet_item.set_active(false);
			state = State.FAILED_WIRED;
			break;

		case NM.DeviceState.UNAVAILABLE:
			ethernet_item.sensitive = false;
			ethernet_item.set_active(false);
			state = State.DISCONNECTED;
			break;
		case NM.DeviceState.DISCONNECTED:
			ethernet_item.sensitive = true;
			ethernet_item.set_active(false);
			state = State.DISCONNECTED;
			break;

		case NM.DeviceState.PREPARE:
		case NM.DeviceState.CONFIG:
		case NM.DeviceState.NEED_AUTH:
		case NM.DeviceState.IP_CONFIG:
		case NM.DeviceState.IP_CHECK:
		case NM.DeviceState.SECONDARIES:
			ethernet_item.sensitive = true;
			ethernet_item.set_active(true);
			state = State.CONNECTING_WIRED;
			break;
		
		case NM.DeviceState.ACTIVATED:
			ethernet_item.sensitive = true;
			ethernet_item.set_active(true);
			state = State.CONNECTED_WIRED;
			break;
		}
	}

}

public class Network.Widgets.PopoverWidget : Gtk.Stack {
	private NM.Client nm_client;
	private NM.RemoteSettings nm_settings;

	Gtk.Box main_box;
	
	GLib.List<WidgetInterface>? network_interface;

	public Network.State state { private set; get; default = Network.State.CONNECTING_WIRED; }


	private const string SETTINGS_EXEC = "/usr/bin/switchboard -o network-plug";

	private Wingpanel.Widgets.Button show_settings_button;

	public signal void settings_shown ();

	public PopoverWidget () {
		network_interface = new GLib.List<WidgetInterface>();

		build_ui ();
		connect_signals ();
		show_all();
	}

	void build_ui () {
		
		main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

		add (main_box);

		show_settings_button = new Wingpanel.Widgets.Button (_("Network Settings…"));
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
			debug ("Ethernet interface added");
		} else {
			stderr.printf ("Unknown device: %s\n", device.get_device_type().to_string());
		}

		if (widget_interface != null) {
			widget_interface.sep = new Wingpanel.Widgets.Separator ();
			main_box.pack_end (widget_interface.sep);
			main_box.pack_end (widget_interface);
			network_interface.append (widget_interface);

			widget_interface.notify["state"].connect(update_state);

			widget_interface.need_settings.connect (show_settings);
		}

		update_all();

		show_all();
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
		Process.spawn_async(null, (SETTINGS_EXEC).split(" "), null, 0, null, null);
		//var cmd = new Granite.Services.SimpleCommand ("/usr/bin", SETTINGS_EXEC);
		//cmd.run();

		settings_shown ();
	}
}
