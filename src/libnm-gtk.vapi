[CCode (cheader_filename = "nm-wifi-dialog.h")]
class NMAWifiDialog : Gtk.Dialog
{
    public NMAWifiDialog (NM.Client client, NM.RemoteSettings settings, NM.Connection connection, NM.Device device, NM.AccessPoint ap, bool secrets_only);
}
