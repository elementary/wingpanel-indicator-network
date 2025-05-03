/*
* SPDX-License-Identifier: LGPL-2.1-or-later
* SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
*/

public class Network.AirplaneModeToggle : SettingsToggle {
    construct {
        action_name = "network.airplane-mode";
        icon_name = "airplane-mode-disabled-symbolic";
        settings_uri = "settings://network";
        text = _("Airplane Mode");

        map.connect (() => {
            var action_group = (SimpleActionGroup) get_action_group ("network");
            action_group.action_state_changed.connect ((action_name, state) => {
                if (action_name == "airplane-mode") {
                    if (state.get_boolean ()) {
                        icon_name = "airplane-mode-symbolic";
                    } else {
                        icon_name = "airplane-mode-disabled-symbolic";
                    }
                }
            });
        });
    }
}
