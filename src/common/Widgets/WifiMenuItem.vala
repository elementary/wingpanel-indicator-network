/*
 * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
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
 */

public class Network.WifiMenuItem : Gtk.Box {
	private List<NM.AccessPoint> _ap;
	public signal void user_action();
	public GLib.ByteArray ssid {
		get {
			return _tmp_ap.get_ssid();
		}
	}

	public Network.State state { get; set; default=Network.State.DISCONNECTED; }

	public uint8 strength {
		get {
			uint8 strength = 0;
			foreach(var ap in _ap) {
				strength = uint8.max(strength, ap.get_strength());
			}
			return strength;
		}
	}

	public bool is_secured {
		get {
			return ap.get_wpa_flags () != NM.@80211ApSecurityFlags.NONE || ap.get_rsn_flags () != NM.@80211ApSecurityFlags.NONE;
		}
	}

	public NM.AccessPoint ap { get { return _tmp_ap; } }
	NM.AccessPoint _tmp_ap;

	Gtk.RadioButton radio_button;
	Gtk.Image img_strength;
	Gtk.Image lock_img;
	Gtk.Image error_img;
	Gtk.Spinner spinner;

	public WifiMenuItem (NM.AccessPoint ap, WifiMenuItem? previous = null) {

		radio_button = new Gtk.RadioButton(null);
		radio_button.margin_start = 6;
		if (previous != null) radio_button.set_group (previous.get_group ());

		radio_button.button_release_event.connect ( (b, ev) => {
			user_action();
			return false;
		});

		img_strength = new Gtk.Image();
		img_strength.margin_end = 6;
		
		lock_img = new Gtk.Image.from_icon_name ("channel-secure-symbolic", Gtk.IconSize.MENU);
		lock_img.margin_start = 6;
		
		/* TODO: investigate this, it has not been tested yet. */
		error_img = new Gtk.Image.from_icon_name ("process-error-symbolic", Gtk.IconSize.MENU);
		error_img.margin_start = 6;

		error_img.set_tooltip_text (_("This wireless network could not be connected to."));
		
		pack_start(radio_button, true, true);
		spinner = new Gtk.Spinner();
		spinner.start();
		spinner.visible = false;
		spinner.no_show_all = !spinner.visible;
		pack_start(spinner, false, false);
		pack_start(error_img, false, false);
		pack_start(lock_img, false, false);
		pack_start(img_strength, false, false);
		
		_ap = new List<NM.AccessPoint>();

		/* Adding the access point triggers update */
		add_ap(ap);

		notify["state"].connect (update);
		radio_button.notify["active"].connect (update);
	}

	/**
	 * Only used for an item which is not displayed: hacky way to have no radio button selected.
	 **/
	public WifiMenuItem.blank () {
		radio_button = new Gtk.RadioButton(null);
	}

	void update_tmp_ap () {
		uint8 strength = 0;
		foreach(var ap in _ap) {
			_tmp_ap = strength > ap.get_strength () ? _tmp_ap : ap;
			strength = uint8.max (strength, ap.get_strength ());
		}
	}

	public void set_active (bool active) {
		radio_button.set_active (active);
	}

	unowned SList get_group () {
		return radio_button.get_group();
	}

	void set_lock_img_tooltip (NM.@80211ApSecurityFlags flags) {
		if((flags & NM.@80211ApSecurityFlags.GROUP_WEP40) != 0) {
			lock_img.set_tooltip_text(_("This network uses 40/64-bit WEP encryption."));
		}
		else if((flags & NM.@80211ApSecurityFlags.GROUP_WEP104) != 0) {
			lock_img.set_tooltip_text(_("This network uses 104/128-bit WEP encryption."));
		}
		else if((flags & NM.@80211ApSecurityFlags.KEY_MGMT_PSK) != 0)  {
			lock_img.set_tooltip_text(_("This network uses WPA encryption."));
		} else {
			lock_img.set_tooltip_text(_("This network uses encryption."));
		}
	}

	private void update () {
		radio_button.label = NM.Utils.ssid_to_utf8 (ap.get_ssid ());

		img_strength.set_from_icon_name("network-wireless-signal-" + strength_to_string(strength) + "-symbolic", Gtk.IconSize.MENU);
		img_strength.show_all();

		lock_img.visible = is_secured;
		set_lock_img_tooltip(ap.get_wpa_flags ());
		lock_img.no_show_all = !lock_img.visible;

		hide_item(error_img);
		hide_item(spinner);
		switch (state) {
		case State.FAILED_WIFI:
			show_item(error_img);
			break;
		case State.CONNECTING_WIFI:
			show_item(spinner);
			if(!radio_button.active) {
				critical("An access point is being connected but not active.");
			}
			break;
		}
	}

	void show_item(Gtk.Widget w) {
		w.visible = true;
		w.no_show_all = !w.visible;
	}

	void hide_item(Gtk.Widget w) {
		w.visible = false;
		w.no_show_all = !w.visible;
		w.hide();
	}

	public void add_ap(NM.AccessPoint ap) {
		_ap.append(ap);
		update_tmp_ap();

		update();
	}

	string strength_to_string(uint8 strength) {
		if(strength < 30)
			return "weak";
		else if(strength < 55)
			return "ok";
		else if(strength < 80)
			return "good";
		else
			return "excellent";
	}

	public bool remove_ap(NM.AccessPoint ap) {
		_ap.remove(ap);

		update_tmp_ap();

		return _ap.length() > 0;
	}


}

