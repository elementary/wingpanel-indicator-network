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

public class Network.Indicator : Wingpanel.Indicator {
	Network.Widgets.DisplayWidget? display_widget = null;

	Network.Widgets.PopoverWidget? popover_widget = null;

	public Indicator () {
		Object (code_name: Wingpanel.Indicator.NETWORK,
				display_name: _("Network"),
				description:_("Network indicator"));
	}

	public override Gtk.Widget get_display_widget () {
		if (display_widget == null) {
			display_widget = new Widgets.DisplayWidget ();
		}

		this.visible = true;

		return display_widget;
	}

	public override Gtk.Widget? get_widget () {
		if (popover_widget == null) {
			popover_widget = new Widgets.PopoverWidget ();

			popover_widget.notify["state"].connect(on_state_changed);

			on_state_changed ();
		}

		return popover_widget;
	}

	void on_state_changed () {
		assert(popover_widget != null);
		assert(display_widget != null);

		display_widget.update_state (popover_widget.state);
	}

	public override void opened () {
		// TODO
	}

	public override void closed () {
		// TODO
	}

}

public Wingpanel.Indicator get_indicator (Module module) {
	debug ("Activating Power Indicator");
	var indicator = new Network.Indicator ();
	return indicator;
}
