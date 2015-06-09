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

public class Network.Widgets.DisplayWidget : Gtk.Box {
	private Gtk.Image image;

	private Gtk.Revealer percent_revealer;

	private Gtk.Label percent_label;

	public DisplayWidget () {
		Object (orientation: Gtk.Orientation.HORIZONTAL);

		build_ui ();
	}

	private void build_ui () {
		image = new Gtk.Image ();
		image.icon_name = "network-wired-symbolic";

		this.pack_start (image);
	}

	private void connect_signals () {
	}

	void set_icon_name (string icon_name) {
		image.icon_name = icon_name;
	}

	public void update_state (Network.State state) {
		switch(state) {
		case Network.State.CONNECTING_WIRED:
			break;
		}
	}

	public void set_percent (int percentage) {
		percent_label.set_label ("%i%%".printf (percentage));
	}
}
