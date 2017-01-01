/*
* Copyright (c) 2015-2016 elementary LLC (http://launchpad.net/wingpanel-indicator-network)
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
*/

public enum Network.State {
    DISCONNECTED,
    DISCONNECTED_WIRED,
    DISCONNECTED_AIRPLANE_MODE,
    CONNECTED_WIRED,
    CONNECTED_WIFI,
    CONNECTED_WIFI_WEAK,
    CONNECTED_WIFI_OK,
    CONNECTED_WIFI_GOOD,
    CONNECTED_WIFI_EXCELLENT,
    CONNECTING_WIFI,
    CONNECTING_WIRED,
    FAILED_WIRED,
    FAILED_WIFI
}

namespace Network.Common.Utils {
    public string network_state_to_string (Network.State state) {
        switch(state) {
        case Network.State.DISCONNECTED:
            return _("Disconnected");
        case Network.State.CONNECTED_WIFI:
        case Network.State.CONNECTED_WIFI_WEAK:
        case Network.State.CONNECTED_WIFI_OK:
        case Network.State.CONNECTED_WIFI_GOOD:
        case Network.State.CONNECTED_WIFI_EXCELLENT:
        case Network.State.CONNECTED_WIRED:
            return _("Connected");
        case Network.State.FAILED_WIRED:
        case Network.State.FAILED_WIFI:
            return _("Failed");
        case Network.State.CONNECTING_WIFI:
        case Network.State.CONNECTING_WIRED:
            return _("Connecting");
        case Network.State.DISCONNECTED_WIRED:
            return _("Cable unplugged");
        case Network.State.DISCONNECTED_AIRPLANE_MODE:
            return _("Airplane mode enabled");
        }
        return _("Unknown");
    }
}

