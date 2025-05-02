/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023 elementary, Inc. (https://elementary.io)
 */

public class Network.SettingsToggle : Gtk.Box {
    public string action_name { get; set; }
    public string icon_name { get; set; }
    public string text { get; set; }
    public string settings_uri { get; set; default = "settings://"; }
    public Gtk.Popover? popover { get; set; default = null; }

    private Gtk.ToggleButton button;
    private Gtk.GestureMultiPress click_controller;
    private Gtk.GestureLongPress long_press_controller;
    private Gtk.EventControllerKey menu_key_controller;

    class construct {
        set_css_name ("settings-toggle");
    }

    construct {
        var image = new Gtk.Image ();

        button = new Gtk.ToggleButton () {
            halign = CENTER,
            image = image
        };

        var label = new Gtk.Label (null) {
            ellipsize = MIDDLE,
            justify = CENTER,
            lines = 2,
            max_width_chars = 13,
            mnemonic_widget = button
        };
        label.get_style_context ().add_class (Granite.STYLE_CLASS_SMALL_LABEL);

        halign = CENTER;
        orientation = VERTICAL;
        spacing = 3;
        add (button);
        add (label);

        bind_property ("action-name", button, "action-name");
        bind_property ("icon-name", image, "icon-name");
        bind_property ("text", label, "label");

        click_controller = new Gtk.GestureMultiPress (this) {
            button = 0,
            exclusive = true
        };
        click_controller.pressed.connect (() => {
            if (click_controller.get_current_button () == Gdk.BUTTON_MIDDLE) {
                try {
                    AppInfo.launch_default_for_uri (settings_uri, null);

                    click_controller.set_state (CLAIMED);
                    click_controller.reset ();

                    var popover = (Gtk.Popover) get_ancestor (typeof (Gtk.Popover));
                    popover.popdown ();
                } catch (Error e) {
                    critical ("Failed to open system settings: %s", e.message);
                }
            }

            if (popover != null) {
                critical ("popover isn't null");

                var sequence = click_controller.get_current_sequence ();
                var event = click_controller.get_last_event (sequence);

                if (event.triggers_context_menu ()) {
                    popover.popup ();

                    click_controller.set_state (CLAIMED);
                    click_controller.reset ();
                }
            }
        });

        notify["popover"].connect (construct_menu);
    }

    private void construct_menu () {
        popover.position = RIGHT;
        popover.relative_to = button;

        long_press_controller = new Gtk.GestureLongPress (this);
        long_press_controller.pressed.connect (() => {
            popover.popup ();
        });

        menu_key_controller = new Gtk.EventControllerKey (this);
        menu_key_controller.key_released.connect ((keyval, keycode, state) => {
            var mods = state & Gtk.accelerator_get_default_mod_mask ();
            switch (keyval) {
                case Gdk.Key.F10:
                    if (mods == Gdk.ModifierType.SHIFT_MASK) {
                        popover.popup ();
                    }
                    break;
                case Gdk.Key.Menu:
                case Gdk.Key.MenuKB:
                    popover.popup ();
                    break;
                default:
                    return;
            }
        });
    }
}
