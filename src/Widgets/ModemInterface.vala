// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2017 elementary LLC. (https://elementary.io)
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
 *
 * Authored by: David Hewitt <davidmhewitt@gmail.com>
 */

public class Network.ModemInterface : Network.AbstractModemInterface {
    private Wingpanel.Widgets.Switch modem_item;

    public ModemInterface (NM.Client nm_client, NM.RemoteSettings nm_settings, NM.Device? _device) {
        device = _device;
        modem_item = new Wingpanel.Widgets.Switch (display_title);

        notify["display-title"].connect (() => {
            modem_item.set_caption (display_title);
        });

        modem_item.get_style_context ().add_class ("h4");
        modem_item.switched.connect (() => {
            if (modem_item.get_active ()) {
                device.set_autoconnect (true);
            } else {
                device.disconnect (() => { debug("Successfully disconnected."); });
            }
        });

        add (modem_item);

        device.state_changed.connect (() => { update (); });
    }

    public override void update () {
        switch (device.state) {
		    /* physically not connected */
		    case NM.DeviceState.UNKNOWN:
		    case NM.DeviceState.UNMANAGED:
		    case NM.DeviceState.UNAVAILABLE:
		    case NM.DeviceState.FAILED:
                modem_item.sensitive = false;
                modem_item.set_active (false);
                state = State.FAILED_MOBILE;
                break;    
		    case NM.DeviceState.DISCONNECTED:            
		    case NM.DeviceState.DEACTIVATING:
                modem_item.sensitive = true;
                modem_item.set_active (true);
			    state = State.FAILED_MOBILE;
			    break;
		    /* configuration */
		    case NM.DeviceState.PREPARE:
		    case NM.DeviceState.CONFIG:
		    case NM.DeviceState.NEED_AUTH:
		    case NM.DeviceState.IP_CONFIG:
		    case NM.DeviceState.IP_CHECK:
		    case NM.DeviceState.SECONDARIES:
                modem_item.sensitive = true;
                modem_item.set_active (true);
			    state = State.CONNECTING_MOBILE;
			    break;
		    /* working */
		    case NM.DeviceState.ACTIVATED:
                modem_item.sensitive = true;
                modem_item.set_active (true);
			    state = State.CONNECTED_MOBILE;
			    break;
		}
    }
}
