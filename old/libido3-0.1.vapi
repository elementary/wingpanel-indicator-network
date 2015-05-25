namespace Ido
{
    [CCode (cheader_filename = "libido/idoswitchmenuitem.h")]
    public class SwitchMenuItem : Gtk.CheckMenuItem
    {
        [CCode (has_construct_function = false)]
        public SwitchMenuItem ();
        public Gtk.Container content_area { get; }
    }
}
