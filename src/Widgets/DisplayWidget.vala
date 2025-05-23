/*
 * SPDX-License-Identifier: GPL-2.1-or-later
 * SPDX-FileCopyrightText: 2015-2025 elementary, Inc. (https://elementary.io)
 */

public class Network.Widgets.DisplayWidget : Gtk.Box {
    private Gtk.Image image;
    private Gtk.Label extra_info_label;
    private Gtk.Revealer extra_info_revealer;

    private uint wifi_animation_timeout;
    private int wifi_animation_state = 0;
    private uint cellular_animation_timeout;
    private int cellular_animation_state = 0;

    construct {
        image = new Gtk.Image.from_icon_name ("panel-network-wired-connected-symbolic", Gtk.IconSize.LARGE_TOOLBAR) {
            pixel_size = 24
        };

        extra_info_label = new Gtk.Label (null) {
            margin_start = 4,
            valign = CENTER,
            vexpand = true
        };

        extra_info_revealer = new Gtk.Revealer () {
            child = extra_info_label,
            transition_type = SLIDE_LEFT
        };

        add (image);
        add (extra_info_revealer);
    }

    public void update_state (Network.State state, bool secure, string? extra_info = null) {
        extra_info_revealer.reveal_child = extra_info != null;
        extra_info_label.label = extra_info;

        if (wifi_animation_timeout > 0) {
            Source.remove (wifi_animation_timeout);
            wifi_animation_timeout = 0;
        }

        if (cellular_animation_timeout > 0) {
            Source.remove (cellular_animation_timeout);
            cellular_animation_timeout = 0;
        }

        switch (state) {
        case Network.State.DISCONNECTED_AIRPLANE_MODE:
            image.icon_name = "airplane-mode-symbolic";
            break;
        case Network.State.CONNECTING_WIRED:
            image.icon_name = "panel-network-wired-acquiring-symbolic";
            break;
        case Network.State.CONNECTED_WIRED:
            image.icon_name = "panel-network-wired-%ssymbolic".printf (secure? "secure-" : "connected-");
            break;
        case Network.State.CONNECTED_WIFI_WEAK:
            image.icon_name = "panel-network-wireless-signal-weak-%ssymbolic".printf (secure? "secure-" : "");
            break;
        case Network.State.CONNECTED_WIFI_OK:
            image.icon_name = "panel-network-wireless-signal-ok-%ssymbolic".printf (secure? "secure-" : "");
            break;
        case Network.State.CONNECTED_WIFI_GOOD:
            image.icon_name = "panel-network-wireless-signal-good-%ssymbolic".printf (secure? "secure-" : "");
            break;
        case Network.State.CONNECTED_WIFI_EXCELLENT:
            image.icon_name = "panel-network-wireless-signal-excellent-%ssymbolic".printf (secure? "secure-" : "");
            break;
        case Network.State.CONNECTING_WIFI:
            wifi_animation_timeout = Timeout.add (300, () => {
                wifi_animation_state = (wifi_animation_state + 1) % 4;
                string strength = "";
                switch (wifi_animation_state) {
                case 0:
                    strength = "weak";
                    break;
                case 1:
                    strength = "ok";
                    break;
                case 2:
                    strength = "good";
                    break;
                case 3:
                    strength = "excellent";
                    break;
                }
                image.icon_name = "panel-network-wireless-signal-" + strength + (secure? "-secure" : "") + "-symbolic";
                return true;
            });
            break;
        case Network.State.CONNECTED_MOBILE_WEAK:
            image.icon_name = "panel-network-cellular-signal-weak-%ssymbolic".printf (secure ? "secure-" : "");
            break;
        case Network.State.CONNECTED_MOBILE_OK:
            image.icon_name = "panel-network-cellular-signal-ok-%ssymbolic".printf (secure ? "secure-" : "");
            break;
        case Network.State.CONNECTED_MOBILE_GOOD:
            image.icon_name = "panel-network-cellular-signal-good-%ssymbolic".printf (secure ? "secure-" : "");
            break;
        case Network.State.CONNECTED_MOBILE_EXCELLENT:
            image.icon_name = "panel-network-cellular-signal-excellent-%ssymbolic".printf (secure ? "secure-" : "");
            break;
        case Network.State.CONNECTING_MOBILE:
            cellular_animation_timeout = Timeout.add (300, () => {
                cellular_animation_state = (cellular_animation_state + 1) % 4;
                string strength = "";
                switch (cellular_animation_state) {
                case 0:
                    strength = "weak";
                    break;
                case 1:
                    strength = "ok";
                    break;
                case 2:
                    strength = "good";
                    break;
                case 3:
                    strength = "excellent";
                    break;
                }

                image.icon_name = "panel-network-cellular-signal-" + strength + (secure ? "secure-" : "") + "-symbolic";
                return true;
            });
            break;
        case Network.State.FAILED_MOBILE:
            image.icon_name = "panel-network-cellular-offline-symbolic";
            break;
        case Network.State.FAILED_WIFI:
        case Network.State.DISCONNECTED:
            image.icon_name = "panel-network-wireless-offline-symbolic";
            break;
        case Network.State.FAILED:
        case Network.State.WIRED_UNPLUGGED:
            image.icon_name = "panel-network-wired-offline-symbolic";
            break;
        default:
            image.icon_name = "panel-network-wired-offline-symbolic";
            critical ("Unknown network state, cannot show the good icon: %s", state.to_string ());
            break;
        }
    }
}
