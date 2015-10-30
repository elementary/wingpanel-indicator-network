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

public abstract class Network.AbstractEtherInterface : Network.WidgetNMInterface {

	public override void update_name (int count) {
		var name = device.get_description ();

		/* At least for docker related interfaces, which can be fairly common */
		if (name.has_prefix ("veth")) {
			display_title = "Virtual wired: %s".printf(name);
		}
		else {
			if (count <= 1) {
				display_title = _("Ethernet");
			}
			else {
				display_title = name;
			}
		}
	}
}
