/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class Network.SettingsToggle : Gtk.Box {
    public string action_name { get; set; }
    public string icon_name { get; set; }
    public string text { get; set; }
    public string settings_uri { get; set; default = "settings://"; }

    class construct {
        set_css_name ("settings-toggle");
    }

    construct {
        var button = new Gtk.ToggleButton () {
            halign = CENTER
        };

        var label = new Gtk.Label (null) {
            ellipsize = MIDDLE,
            justify = CENTER,
            lines = 2,
            max_width_chars = 13,
            mnemonic_widget = button
        };
        label.add_css_class (Granite.STYLE_CLASS_SMALL_LABEL);

        halign = CENTER;
        orientation = VERTICAL;
        spacing = 3;
        append (button);
        append (label);

        bind_property ("action-name", button, "action-name");
        bind_property ("icon-name", button, "icon-name");
        bind_property ("text", label, "label");

        var middle_click_gesture = new Gtk.GestureClick () {
            button = Gdk.BUTTON_MIDDLE
        };
        middle_click_gesture.pressed.connect (() => {
            try {
                AppInfo.launch_default_for_uri (settings_uri, null);

                var popover = (Gtk.Popover) get_ancestor (typeof (Gtk.Popover));
                popover.popdown ();
            } catch (Error e) {
                critical ("Failed to open system settings: %s", e.message);
            }
        });

        add_controller (middle_click_gesture);
    }
}
