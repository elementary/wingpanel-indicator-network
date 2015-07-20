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

public class Network.Widgets.PopoverWidget : Gtk.Stack {
	private NM.Client nm_client;
	private NM.RemoteSettings nm_settings;

	Gtk.Box main_box;
	
	GLib.List<WidgetNMInterface>? network_interface;

	public Network.State state { private set; get; default = Network.State.CONNECTING_WIRED; }


	private const string SETTINGS_EXEC = "/usr/bin/switchboard -o network-plug";

	private Wingpanel.Widgets.Button show_settings_button;

	public signal void settings_shown ();

	public PopoverWidget () {
		network_interface = new GLib.List<WidgetNMInterface>();

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
		WidgetNMInterface? widget_interface = null;

		if (device is NM.DeviceWifi) {
			widget_interface = new WifiInterface (nm_client, nm_settings, device);
			debug ("Wifi interface added");
		} else if (device is NM.DeviceEthernet) {
			widget_interface = new EtherInterface (nm_client, nm_settings, device);
			debug ("Ethernet interface added");
		} else {
			debug ("Unknown device: %s\n", device.get_device_type().to_string());
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
		try {
			Process.spawn_async(null, (SETTINGS_EXEC).split(" "), null, 0, null, null);
		}
		catch (SpawnError e) {
			critical ("Could not launch settings.");
		}
		//var cmd = new Granite.Services.SimpleCommand ("/usr/bin", SETTINGS_EXEC);
		//cmd.run();

		settings_shown ();
	}
}
