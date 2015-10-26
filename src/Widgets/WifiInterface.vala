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
	Gtk.Revealer revealer;
	
	public WifiInterface(NM.Client nm_client, NM.RemoteSettings nm_settings, NM.Device? _device) {
		init_wifi_interface (nm_client, nm_settings, _device);

		wifi_item.set_caption (display_title);
		notify["display-title"].connect ( () => {
			wifi_item.set_caption (display_title);
		});

		wifi_item.switched.connect (() => {
			var active = wifi_item.get_active ();
			if (active != !software_locked) {
				rfkill.set_software_lock (RFKillDeviceType.WLAN, !active);
				nm_client.wireless_set_enabled (active);
			}
		});
	}

	construct {
		orientation = Gtk.Orientation.VERTICAL;
		wifi_item = new Wingpanel.Widgets.Switch ("");
		wifi_item.get_style_context ().add_class ("h4");
		pack_start (wifi_item);

		var scrolled_box = new AutomaticScrollBox (null, null);
		scrolled_box.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
		scrolled_box.add_with_viewport (wifi_list);

		revealer = new Gtk.Revealer ();
		revealer.add (scrolled_box);

		pack_start (revealer);
	}

	public override void update () {
		base.update ();

		wifi_item.set_sensitive (!hardware_locked);
		wifi_item.set_active (!locked);

		active_ap = wifi_device.get_active_access_point ();

		if (wifi_device.state == NM.DeviceState.UNAVAILABLE || state == Network.State.FAILED_WIFI) {
			revealer.reveal_child = false;
		} else {
			revealer.reveal_child = true;
		}
	}
	
	protected override void wifi_activate_cb (WifiMenuItem i) {

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

