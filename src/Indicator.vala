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

    public bool is_in_session { get; set; default = false; }

    public Indicator (bool is_in_session) {
        Object (code_name: Wingpanel.Indicator.NETWORK,
                display_name: _("Network"),
                description: _("Network indicator"),
                is_in_session: is_in_session,
                visible: true);

        display_widget = new Widgets.DisplayWidget ();

        popover_widget = new Widgets.PopoverWidget (is_in_session);
        popover_widget.notify["state"].connect (on_state_changed);
        popover_widget.notify["secure"].connect (on_state_changed);
        popover_widget.notify["extra-info"].connect (on_state_changed);
        popover_widget.settings_shown.connect (() => { close (); });

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
    }

    private void start_monitor () {
        network_monitor = NetworkMonitor.get_default ();

        network_monitor.network_changed.connect ((availabe) => {
            if (!is_in_session) {
                return;
            }

            if (network_monitor.get_connectivity () == NetworkConnectivity.FULL || network_monitor.get_connectivity () == NetworkConnectivity.PORTAL) {
                try {
                    var appinfo = AppInfo.create_from_commandline ("io.elementary.capnet-assist", null, AppInfoCreateFlags.NONE);
                    appinfo.launch (null, null);
                } catch (Error e) {
                    warning ("%s\n", e.message);
                }
            }
        });
    }

    public override void opened () {
        // TODO
    }

    public override void closed () {
        // TODO
    }
}

public Wingpanel.Indicator get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Network Indicator");
    var indicator = new Network.Indicator (server_type == Wingpanel.IndicatorManager.ServerType.SESSION);
    return indicator;
}
