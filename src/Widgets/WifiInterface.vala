/*
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

public class Network.WifiInterface : Network.WidgetNMInterface {
	RFKillManager rfkill;
	bool updating_rfkill = false;
	NM.DeviceWifi? wifi_device;
	private NM.AccessPoint? active_ap;
	private Wingpanel.Widgets.Switch wifi_item;
	Gtk.ListBox wifi_list;

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
		scrolled_box.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

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

			/* This can happen at start, when the access point list is populated. */
			if (!found) {
				debug ("Active AP not added");
			}
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
		if(strength < 30)
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
		case NM.DeviceState.FAILED:
			state = State.FAILED_WIFI;
			if(active_wifi_item != null) {
				active_wifi_item.state = state;
			}
			break;

		case NM.DeviceState.DEACTIVATING:
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
			/* NM.Connection? connection = null;
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

