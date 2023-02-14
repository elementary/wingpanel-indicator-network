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
    private Gtk.ToggleButton ethernet_item;

    private static Gtk.CssProvider provider;

    static construct {
        provider = new Gtk.CssProvider ();
        provider.load_from_resource ("io/elementary/wingpanel/network/Indicator.css");
    }

    public EtherInterface (NM.Client nm_client, NM.Device? _device) {
        device = _device;


        ethernet_item = new Gtk.ToggleButton () {
            halign = Gtk.Align.CENTER,
            image = new Gtk.Image.from_icon_name ("network-wired-symbolic", Gtk.IconSize.MENU)
        };
        ethernet_item.get_style_context ().add_class ("circular");
        ethernet_item.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var label = new Gtk.Label (display_title) {
            ellipsize = Pango.EllipsizeMode.MIDDLE,
            max_width_chars = 16
        };
        label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        notify["display-title"].connect (() => {
            label.label = display_title;
        });

        ethernet_item.toggled.connect (() => {
            debug ("update");
            if (ethernet_item.active && device.get_state () == NM.DeviceState.DISCONNECTED) {
                var connection = NM.SimpleConnection.new ();
                var remote_array = device.get_available_connections ();
                if (remote_array == null) {
                    critical ("Unable to find an ethernet connection to activate");
                } else {
                    connection.set_path (remote_array.get (0).get_path ());
                    nm_client.activate_connection_async.begin (connection, device, null, null, null);
                }
            } else if (!ethernet_item.active && device.get_state () == NM.DeviceState.ACTIVATED) {
                device.disconnect_async.begin (null, () => { debug ("Successfully disconnected."); });
            }
        });

        hexpand = true;
        orientation = Gtk.Orientation.VERTICAL;
        spacing = 3;
        add (ethernet_item);
        add (label);

        device.state_changed.connect (() => { update (); });
    }

    public override void update_name (int count) {
        var name = device.get_description ();

        /* At least for docker related interfaces, which can be fairly common */
        if (name.has_prefix ("veth")) {
            display_title = _("Virtual network: %s").printf (name);
        } else {
            if (count <= 1) {
                display_title = _("Wired");
            } else {
                display_title = name;
            }
        }
    }

    public override void update () {
        switch (device.get_state ()) {
        case NM.DeviceState.UNKNOWN:
        case NM.DeviceState.UNMANAGED:
        case NM.DeviceState.DEACTIVATING:
        case NM.DeviceState.FAILED:
            sensitive = false;
            ethernet_item.active = false;
            state = State.FAILED;
            break;

        case NM.DeviceState.UNAVAILABLE:
            sensitive = false;
            ethernet_item.active = false;
            state = State.WIRED_UNPLUGGED;
            break;
        case NM.DeviceState.DISCONNECTED:
            sensitive = true;
            ethernet_item.active = false;
            state = State.WIRED_UNPLUGGED;
            break;

        case NM.DeviceState.PREPARE:
        case NM.DeviceState.CONFIG:
        case NM.DeviceState.NEED_AUTH:
        case NM.DeviceState.IP_CONFIG:
        case NM.DeviceState.IP_CHECK:
        case NM.DeviceState.SECONDARIES:
            sensitive = true;
            ethernet_item.active = true;
            state = State.CONNECTING_WIRED;
            break;

        case NM.DeviceState.ACTIVATED:
            sensitive = true;
            ethernet_item.active = true;
            state = State.CONNECTED_WIRED;
            break;
        }

        if (ethernet_item.active) {
            ((Gtk.Image ) ethernet_item.image).icon_name = "network-wired-symbolic";
        } else {
            ((Gtk.Image ) ethernet_item.image).icon_name = "network-wired-disconnected-symbolic";
        }
    }
}
