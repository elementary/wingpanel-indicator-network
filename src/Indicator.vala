/*
* Copyright (c) 2015-2018 elementary LLC (http://launchpad.net/wingpanel-indicator-network)
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

public class Network.Indicator : Wingpanel.Indicator {
    Network.Widgets.DisplayWidget? display_widget = null;
    Network.Widgets.PopoverWidget? popover_widget = null;

    NetworkMonitor network_monitor;

    private RFKillManager rfkill;
    private Gtk.GestureMultiPress gesture_click;
    private SimpleAction airplane_action;

    public bool is_in_session { get; set; default = false; }

    public Indicator (bool is_in_session) {
        GLib.Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        GLib.Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");

        unowned var icon_theme = Gtk.IconTheme.get_default ();
        icon_theme.add_resource_path ("/io/elementary/wingpanel/network");

        Object (code_name: Wingpanel.Indicator.NETWORK,
                is_in_session: is_in_session,
                visible: true);

        display_widget = new Widgets.DisplayWidget ();

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("io/elementary/wingpanel/network/Indicator.css");

        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        popover_widget = new Widgets.PopoverWidget (is_in_session);
        popover_widget.notify["state"].connect (on_state_changed);
        popover_widget.notify["secure"].connect (on_state_changed);
        popover_widget.notify["extra-info"].connect (on_state_changed);
        popover_widget.settings_shown.connect (() => { close (); });

        if (is_in_session) {
            gesture_click = new Gtk.GestureMultiPress (display_widget) {
                button = button = Gdk.BUTTON_MIDDLE
            };

            gesture_click.pressed.connect (() => {
                airplane_action.activate (null);
            });
        }

        rfkill = new RFKillManager ();
        rfkill.open ();

        airplane_action = new SimpleAction.stateful ("airplane-mode", null, new Variant.boolean (rfkill.get_airplane_mode ()));
        airplane_action.activate.connect (() => {
            rfkill.set_software_lock (ALL, !rfkill.get_airplane_mode ());
        });

        rfkill.device_changed.connect (() => {
            airplane_action.set_state (new Variant.boolean (rfkill.get_airplane_mode ()));
        });

        var action_group = (SimpleActionGroup) popover_widget.get_action_group ("network");
        action_group.add_action (airplane_action);

        update_tooltip ();
        on_state_changed ();
        start_monitor ();
    }

    public override Gtk.Widget get_display_widget () {
        return display_widget;
    }

    public override Gtk.Widget? get_widget () {
        return popover_widget;
    }

    void on_state_changed () {
        assert (popover_widget != null);
        assert (display_widget != null);

        display_widget.update_state (popover_widget.state, popover_widget.secure, popover_widget.extra_info);

        update_tooltip ();
    }

    private void start_monitor () {
        network_monitor = NetworkMonitor.get_default ();

        network_monitor.network_changed.connect ((availabe) => {
            if (!is_in_session) {
                return;
            }

            if (network_monitor.get_connectivity () == NetworkConnectivity.PORTAL) {
                try {
                    var appinfo = new DesktopAppInfo ("io.elementary.capnet-assist.desktop");
                    appinfo.launch (null, null);
                } catch (Error e) {
                    warning (e.message);
                }
            }

            update_tooltip ();
        });
    }

    public override void opened () {
        if (popover_widget != null) {
            popover_widget.opened ();
        }
    }

    public override void closed () {
        if (popover_widget != null) {
            popover_widget.closed ();
        }
    }

    private void update_tooltip () {
        var tooltip_markup = "";
        switch (popover_widget.state) {
            case Network.State.CONNECTING_WIRED:
                /* If there's only one active ethernet connection,
                we get back the string "Wired". We won't want to
                show the user Connecting to "Wired" so we'll have
                to show them something else if we get back
                "Wired" from get_active_wired_name () */

                string active_wired_name = get_active_wired_name ();

                if (active_wired_name == _("Wired")) {
                    tooltip_markup = _("Connecting to wired network");
                } else {
                    tooltip_markup = _("Connecting to “%s”").printf (active_wired_name);
                }
                break;
            case Network.State.CONNECTING_WIFI:
            case Network.State.CONNECTING_MOBILE:
                tooltip_markup = _("Connecting to “%s”").printf (get_active_wifi_name ());
                break;
            case Network.State.CONNECTED_WIRED:
                string active_wired_name = get_active_wired_name ();

                if (active_wired_name == _("Wired")) {
                    tooltip_markup = _("Connected to wired network");
                } else {
                    tooltip_markup = _("Connected to “%s”").printf (active_wired_name);
                }
                break;
            case Network.State.CONNECTED_WIFI_WEAK:
            case Network.State.CONNECTED_WIFI_OK:
            case Network.State.CONNECTED_WIFI_GOOD:
            case Network.State.CONNECTED_WIFI_EXCELLENT:
            case Network.State.CONNECTED_MOBILE_WEAK:
            case Network.State.CONNECTED_MOBILE_OK:
            case Network.State.CONNECTED_MOBILE_GOOD:
            case Network.State.CONNECTED_MOBILE_EXCELLENT:
                tooltip_markup = _("Connected to “%s”").printf (get_active_wifi_name ());
                break;
            case Network.State.FAILED:
            case Network.State.FAILED_WIFI:
            case Network.State.FAILED_MOBILE:
                tooltip_markup = _("Failed to connect");
                break;
            case Network.State.DISCONNECTED:
            case Network.State.DISCONNECTED_AIRPLANE_MODE:
                tooltip_markup = _("Disconnected");
                break;
            default:
                tooltip_markup = _("Not connected");
                break;
        }

        if (is_in_session) {
            var middle_click_markup = popover_widget.state == Network.State.DISCONNECTED_AIRPLANE_MODE ?
                                    _("Middle-click to turn airplane mode off") :
                                    _("Middle-click to turn airplane mode on");

            display_widget.tooltip_markup = "%s\n%s".printf (
                tooltip_markup,
                Granite.TOOLTIP_SECONDARY_TEXT_MARKUP.printf (middle_click_markup)
            );
        } else {
            display_widget.tooltip_markup = tooltip_markup;
        }
    }

    private string get_active_wired_name () {
        foreach (unowned var iface in popover_widget.network_interface) {
            if (iface is Network.EtherInterface) {
                var active_wired_name = iface.display_title;
                debug ("Active network (Wired): %s".printf (active_wired_name));
                return active_wired_name;
            }
        }

        return _("unknown network");
    }

    private string get_active_wifi_name () {
        foreach (unowned var iface in popover_widget.network_interface) {
            if (iface is WifiInterface) {
                var active_wifi_name = ((Network.WifiInterface) iface).active_ap_name;
                debug ("Active network (WiFi): %s".printf (active_wifi_name));
                return active_wifi_name;
            }
        }

        return _("unknown network");
    }
}

public Wingpanel.Indicator get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Network Indicator");
    var indicator = new Network.Indicator (server_type == Wingpanel.IndicatorManager.ServerType.SESSION);
    return indicator;
}
