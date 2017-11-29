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

public abstract class Network.AbstractHotspotInterface : Network.WidgetNMInterface {
	protected AbstractWifiInterface root_iface;

	public override void update_name (int count) {
		if (count <= 1) {
			display_title = _("Hotspot");
		} else {
			display_title = _("Hotspot %s").printf (device.get_description ());
		}
	}

	public override void update () {
#if PLUG_NETWORK
		if (Utils.Hotspot.get_device_is_hotspot (root_iface.wifi_device, root_iface.nm_client)) {
			state = State.CONNECTED_WIFI;
		} else {
			state = State.DISCONNECTED;
		}
#endif
	}
	
}
