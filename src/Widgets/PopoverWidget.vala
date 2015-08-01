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

public class Network.Widgets.PopoverWidget : Network.Widgets.NMVisualizer {
	Gtk.Box main_box;
	
	private const string SETTINGS_EXEC = "/usr/bin/switchboard -o network-plug";

	private Wingpanel.Widgets.Button show_settings_button;

	public signal void settings_shown ();

	public PopoverWidget () {
		connect_signals ();
	}


	protected override void build_ui () {
		
		main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

		add (main_box);

		show_settings_button = new Wingpanel.Widgets.Button (_("Network Settings…"));
		main_box.pack_end (show_settings_button);
	}
	
	protected override void remove_interface (WidgetNMInterface widget_interface) {
		if (widget_interface.sep != null) {
			widget_interface.sep.destroy ();
		}

		widget_interface.destroy ();
	}

	protected override void add_interface (WidgetNMInterface widget_interface) {
		widget_interface.sep = new Wingpanel.Widgets.Separator ();
		main_box.pack_end (widget_interface.sep);
		main_box.pack_end (widget_interface);

		widget_interface.need_settings.connect (show_settings);
	}
	
	void connect_signals () {
		show_settings_button.clicked.connect (show_settings);
	}

	void show_settings () {
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
