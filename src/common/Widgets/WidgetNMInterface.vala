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

#if INDICATOR_NETWORK
public abstract class Network.WidgetNMInterface : Gtk.Box {
	protected NM.Device? device;
#else
public abstract class Network.WidgetNMInterface : Network.Widgets.Page {
#endif
	public Network.State state { get; protected set; default = Network.State.DISCONNECTED; }

	public string display_title { get; protected set; default = "Unknown interface"; }

#if PLUG_NETWORK
	construct {
		notify["display-title"].connect ( () => {
			device_label.label = display_title;
		});
	}
#endif

#if INDICATOR_NETWORK
	public Wingpanel.Widgets.Separator? sep = null;

	public signal void show_dialog (Gtk.Widget w);
	public signal void need_settings ();
#endif

	public bool is_device (NM.Device device) {
		return device == this.device;
	}
	
#if PLUG_NETWORK
	public override void update () {
		base.update ();
#else
	public virtual void update () {
#endif
	}

	public virtual void update_name (int count) {
		display_title = _("Unknown type: %s ").printf (device.get_description ());
	}
}
