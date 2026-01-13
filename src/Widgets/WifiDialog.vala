/*
* SPDX-License-Identifier: LGPL-2.1-or-later
* SPDX-FileCopyrightText: 2026 elementary, Inc. (https://elementary.io)
*/

public class Network.WifiDialog : Granite.MessageDialog {
    public NM.AccessPoint access_point { get; set; }
    public NM.Connection connection { get; set; }

    private Gtk.Button connect_button;
    private Gtk.Entry password_entry;

    public WifiDialog () {
        Object (
            image_icon: new ThemedIcon ("network-wireless"),
            primary_text: _("Join Wi-Fi Network"),
            secondary_text: _("Enter the password to join this Wi-Fi network."),
            buttons: Gtk.ButtonsType.CANCEL
        );
    }

    construct {
        password_entry = new Gtk.Entry () {
            activates_default = true,
            input_hints = Gtk.InputHints.NO_SPELLCHECK,
            input_purpose = PASSWORD,
            visibility = false
        };

        var password_header = new Granite.HeaderLabel (_("Password")) {
            mnemonic_widget = password_entry
        };

        var content_box = new Gtk.Box (VERTICAL, 3);
        content_box.add (password_header);
        content_box.add (password_entry);

        custom_bin.add (content_box);
        custom_bin.show_all ();

        connect_button = (Gtk.Button) add_button (_("Connect"), Gtk.ResponseType.ACCEPT);
        connect_button.sensitive = false;
        connect_button.has_default = true;

        notify["access-point"].connect (() => {
            primary_text = _("Join “%s”").printf (
                NM.Utils.ssid_to_utf8 (access_point.get_ssid ().get_data ())
            );
        });

        password_entry.changed.connect (validate_connection);
    }

    private void validate_connection () {
        if (connection == null) {
            connect_button.sensitive = false;
            return;
        }

        if (password_entry.text_length == 0) {
            connect_button.sensitive = false;
            return;
        }

        // GenericArray<unowned string> hints;
        // var secret_setting_name = connection.need_secrets (out hints);
        // var secret_setting = connection.get_setting_by_name (secret_setting_name);

        connect_button.sensitive = true;
    }
}
