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

public class Network.WifiInterface : Network.AbstractWifiInterface {
	Wingpanel.Widgets.Switch wifi_item;
	
	public WifiInterface(NM.Client nm_client, NM.RemoteSettings nm_settings, NM.Device? _device) {
		set_orientation(Gtk.Orientation.VERTICAL);
	
		init (nm_client, nm_settings, _device);
		
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
		
		scrolled_box.add_with_viewport(wifi_list);

		pack_start (scrolled_box);

		
	}

	public override void update () {
		base.update ();
		
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
	}

}

