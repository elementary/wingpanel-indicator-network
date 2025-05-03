/*
* Copyright 2015-2021 elementary, Inc. (https://elementary.io)
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

public class Network.EtherInterface : Network.WidgetNMInterface {
    private SettingsToggle ethernet_item;
    private SimpleAction toggle_ethernet_action;

    public EtherInterface (NM.Client nm_client, NM.Device? _device) {
        device = _device;

        ethernet_item = new SettingsToggle () {
            action_name = "ethernet.toggle",
            icon_name = "panel-network-wired-connected-symbolic",
            settings_uri = "settings://network",
            text = display_title
        };

        add (ethernet_item);

        bind_property ("display-title", ethernet_item, "text");

        toggle_ethernet_action = new SimpleAction.stateful ("toggle", null, new Variant.boolean (true));
        toggle_ethernet_action.activate.connect (() => {
            if (device.get_state () == NM.DeviceState.DISCONNECTED) {
                var connection = NM.SimpleConnection.new ();
                var remote_array = device.get_available_connections ();
                if (remote_array == null) {
                    critical ("Unable to find an ethernet connection to activate");
                } else {
                    connection.set_path (remote_array.get (0).get_path ());
                    nm_client.activate_connection_async.begin (connection, device, null, null, null);
                }
            } else if (device.get_state () == NM.DeviceState.ACTIVATED) {
                device.disconnect_async.begin (null, () => { debug ("Successfully disconnected."); });
            }
        });

        update ();
        device.state_changed.connect (update);

        var action_group = new SimpleActionGroup ();
        action_group.add_action (toggle_ethernet_action);

        insert_action_group ("ethernet", action_group);
    }

    private void update () {
        switch (device.get_state ()) {
        case NM.DeviceState.UNKNOWN:
        case NM.DeviceState.UNMANAGED:
        case NM.DeviceState.DEACTIVATING:
        case NM.DeviceState.FAILED:
            toggle_ethernet_action.set_state (new Variant.boolean (false));
            toggle_ethernet_action.set_enabled (false);
            state = State.FAILED;
            break;

        case NM.DeviceState.UNAVAILABLE:
            toggle_ethernet_action.set_state (new Variant.boolean (false));
            toggle_ethernet_action.set_enabled (false);
            state = State.WIRED_UNPLUGGED;
            break;
        case NM.DeviceState.DISCONNECTED:
            toggle_ethernet_action.set_state (new Variant.boolean (false));
            toggle_ethernet_action.set_enabled (true);
            state = State.WIRED_UNPLUGGED;
            break;

        case NM.DeviceState.PREPARE:
        case NM.DeviceState.CONFIG:
        case NM.DeviceState.NEED_AUTH:
        case NM.DeviceState.IP_CONFIG:
        case NM.DeviceState.IP_CHECK:
        case NM.DeviceState.SECONDARIES:
            toggle_ethernet_action.set_enabled (true);
            toggle_ethernet_action.set_state (new Variant.boolean (true));
            state = State.CONNECTING_WIRED;
            break;

        case NM.DeviceState.ACTIVATED:
            toggle_ethernet_action.set_enabled (true);
            toggle_ethernet_action.set_state (new Variant.boolean (true));
            state = State.CONNECTED_WIRED;
            break;
        }

        ethernet_item.icon_name = get_icon_name (device.get_state ());
    }

    private static string get_icon_name (NM.DeviceState state) {
        var base_name = "panel-network-wired";
        var state_name =  "";

        switch (state) {
            case UNKNOWN:
            case UNMANAGED:
            case DEACTIVATING:
            case FAILED:
                state_name = "error";
                break;

            case UNAVAILABLE:
                state_name = "no-route";
                break;
            case DISCONNECTED:
                state_name = "offline";
                break;

            case PREPARE:
            case CONFIG:
            case NEED_AUTH:
            case IP_CONFIG:
            case IP_CHECK:
            case SECONDARIES:
                state_name = "acquiring";
                break;

            case ACTIVATED:
                state_name = "connected";
                break;
        }

        return string.joinv ("-", { base_name, state_name, "symbolic" });
    }
}
