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

public abstract class Network.AbstractWifiInterface : Network.WidgetNMInterface {
	protected RFKillManager rfkill;
	protected bool updating_rfkill = false;
	protected NM.DeviceWifi? wifi_device;
	protected NM.AccessPoint? active_ap;
	
	protected Gtk.ListBox wifi_list;

	protected NM.Client nm_client;
	protected NM.RemoteSettings nm_settings;
	
	protected WifiMenuItem? active_wifi_item = null;
	protected WifiMenuItem? blank_item = null;

	public void init_wifi_interface (NM.Client nm_client, NM.RemoteSettings nm_settings, NM.Device? _device) {
		
	
		this.nm_client = nm_client;
		this.nm_settings = nm_settings;
		device = _device;
		wifi_device = device as NM.DeviceWifi;
		blank_item = new WifiMenuItem.blank ();
		
		wifi_list = new Gtk.ListBox ();
		wifi_list.set_sort_func (sort_func);
		
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

		base.update ();
	}

	protected abstract void wifi_activate_cb (WifiMenuItem i);

	private int sort_func (Gtk.ListBoxRow r1, Gtk.ListBoxRow r2) {
		if (r1 == null || r2 == null) {
			return 0;
		}

		var w1 = (WifiMenuItem)r1.get_child ();
		var w2 = (WifiMenuItem)r2.get_child ();

		if (w1.ap.get_strength () > w2.ap.get_strength ()) {
			return -1;
		} else if (w1.ap.get_strength () < w2.ap.get_strength ()) {
			return 1;
		} else {
			return 0;
		}
	}
}
