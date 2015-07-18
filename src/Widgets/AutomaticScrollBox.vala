public class AutomaticScrollBox : Gtk.ScrolledWindow {
	public AutomaticScrollBox (Gtk.Adjustment? hadj, Gtk.Adjustment? vadj) {

		add.connect( (w) => {
			Gtk.Bin bin = (Gtk.Bin)w;
			Gtk.Widget child = bin.get_child();
			if (child != null) {
				monitor_size(child);
			}
			else {
				bin.add.connect(monitor_size);
			}
		});
	}

	void monitor_size (Gtk.Widget child) {
		child.size_allocate.connect( (rect) => {
			height_request = int.min(512, rect.height);
		});
	}
}
