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

public class Network.Widgets.PopoverWidget : Network.Widgets.NMVisualizer {
    Gtk.Box main_box;
    Gtk.Box other_box;
    Gtk.Box wifi_box;
    Gtk.Box settings_box;

    private Wingpanel.Widgets.Button show_settings_button;
    private Wingpanel.Widgets.Button hidden_item;

    public signal void settings_shown ();

    bool is_dm () {
        return Environment.get_user_name () == Services.SettingsManager.get_default ().desktopmanager_user;
    }

    public PopoverWidget () {
        show_settings_button.clicked.connect (show_settings);

        hidden_item.clicked.connect (() => {
            bool found = false;
            wifi_box.get_children ().foreach ((child) => {
                if (child is Network.WifiInterface && ((Network.WifiInterface) child).hidden_sensitivity && !found) {
                    ((Network.WifiInterface) child).connect_to_hidden ();
                    found = true;
                }
            });
        });
    }

    protected override void build_ui () {
        other_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        wifi_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        settings_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.add (other_box);
        main_box.add (wifi_box);
        main_box.add (settings_box);

        add (main_box);

        if (!is_dm ()) {
            show_settings_button = new Wingpanel.Widgets.Button (_("Network Settings…"));
            settings_box.pack_end (show_settings_button);

            hidden_item = new Wingpanel.Widgets.Button (_("Connect to Hidden Network…"));
            hidden_item.no_show_all = true;
            settings_box.pack_start (hidden_item);
        }
    }

    protected override void remove_interface (WidgetNMInterface widget_interface) {
        if (widget_interface.sep != null) {
            widget_interface.sep.destroy ();
        }

        widget_interface.destroy ();
    }

    protected override void add_interface (WidgetNMInterface widget_interface) {
        Gtk.Box container_box = other_box;

        if (widget_interface is Network.WifiInterface) {
            container_box = wifi_box;
            hidden_item.no_show_all = false;
            hidden_item.show_all ();

            ((Network.WifiInterface) widget_interface).notify["hidden-sensitivity"].connect (() => {
                bool hidden_sensitivity = false;

                wifi_box.get_children ().foreach ((child) => {
                    if (child is Network.WifiInterface) {
                        hidden_sensitivity = hidden_sensitivity || ((Network.WifiInterface) child).hidden_sensitivity;
                    }

                    hidden_item.sensitive = hidden_sensitivity;
                });
            });
        }

        if (!is_dm () || main_box.get_children ().length () > 0) {
            widget_interface.sep = new Wingpanel.Widgets.Separator ();
            container_box.pack_end (widget_interface.sep);
        }

        container_box.pack_end (widget_interface);

        widget_interface.need_settings.connect (show_settings);
    }

    void show_settings () {
        if (!is_dm ()) {
            var list = new List<string> ();
            list.append ("network");

            try {
                var appinfo = AppInfo.create_from_commandline ("switchboard", null, AppInfoCreateFlags.SUPPORTS_URIS);
                appinfo.launch_uris (list, null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }

            settings_shown ();
        }
    }
}
