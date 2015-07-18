/*-
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

/** A scroll box that will takes it child height unless it is higher than 512.
 * If it is actually higher than 512, then it will stick to 512.
 * Reparenting the child is not supported (you have to destroy the
 * AutomaticScrollBox that held it if it must be used elsewhere).
 *
 * Adding with something different from add_with_viewport is not supported yet.
 **/
public class AutomaticScrollBox : Gtk.ScrolledWindow {

	/** The adjustments are here to ensure the compatibility with Gtk.ScrolledWindow,
	 * but you should probably not use them, as the height of this widget is dynamic.
	 **/
	public AutomaticScrollBox (Gtk.Adjustment? hadj = null, Gtk.Adjustment? vadj = null) {

		set_hadjustment (hadj);
		set_vadjustment (vadj);
		
		/* Listen to the add signal. Every widget added directly to the ScrolledWindow
		 * is supposed to be a Gtk.Bin, which is ATM always verified. */
		add.connect( (w) => {
			if (w is Gtk.Scrollable && w is Gtk.Bin) {
				Gtk.Bin bin = (Gtk.Bin)w;

				Gtk.Widget child = bin.get_child();
				
				if (child != null) {
					monitor_size(child);
				}
				else {
					bin.add.connect(monitor_size);
				}
			}
		});
	}

	void monitor_size (Gtk.Widget child) {

		child.size_allocate.connect_after( (rect) => {

			/* Let's wait for all the signals to be flushed */
			Idle.add( () => {
				int height;
				child.get_preferred_height(out height, null);
				height_request = int.min(512, height);
				queue_resize();
				return false;
			});
		});
	}
}
