[CCode (cheader_filename = "nm-wifi-dialog.h")]
class NMAWifiDialog : Gtk.Dialog {
    public NMAWifiDialog (NM.Client client, NM.RemoteSettings settings, NM.Connection 0connection, NM.Device device, NM.AccessPoint ap, bool secrets_only);
    public NMAWifiDialog.for_other (NM.Client client, NM.RemoteSettings settings);
    public NM.Connection get_connection (out NM.Device device, out NM.AccessPoint ap);
}
