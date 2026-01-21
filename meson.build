project(
    'network',
    'vala', 'c',
    version: '8.0.1'
)

gettext_name = meson.project_name() + '-indicator'
gnome = import('gnome')
i18n = import('i18n')

prefix = get_option('prefix')
libdir = join_paths(prefix, get_option('libdir'))

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')

add_project_arguments(
    '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
    language: 'vala'
)

add_project_arguments('-DG_LOG_DOMAIN="io.elementary.wingpanel.network"', language:'c')

wingpanel_dep = dependency('wingpanel')
wingpanel_indicatorsdir = wingpanel_dep.get_pkgconfig_variable('indicatorsdir', define_variable: ['libdir', libdir])

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name() + '-indicator')
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

gresource = gnome.compile_resources(
    'gresource',
    'data' / 'network.gresource.xml',
    source_dir: 'data'
)

polkit_dep = dependency ('polkit-gobject-1')

shared_module(
    meson.project_name(),
    config_file,
    'src/Indicator.vala',
    'src/rfkill.vala',
    'src/Utils.vala',
    'src/Widgets/DisplayWidget.vala',
    'src/Widgets/EtherInterface.vala',
    'src/Widgets/ModemInterface.vala',
    'src/Widgets/PopoverWidget.vala',
    'src/Widgets/SettingsToggle.vala',
    'src/Widgets/VpnInterface.vala',
    'src/Widgets/VpnMenuItem.vala',
    'src/Widgets/WidgetNMInterface.vala',
    'src/Widgets/WifiDialog.vala',
    'src/Widgets/WifiInterface.vala',
    'src/Widgets/WifiMenuItem.vala',
    gresource,
    dependencies: [
        dependency('gio-2.0', version: '>=2.74'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('libnm', version: '>=1.24'),
        dependency('libnma'),
        polkit_dep,
        meson.get_compiler('vala').find_library('posix'),
        wingpanel_dep
    ],
    install: true,
    install_dir : wingpanel_indicatorsdir
)

subdir('data')
subdir('po')
vapigen = find_program('vapigen', required: false)
g_ir_dep = dependency('gobject-introspection-1.0', required: false)
if vapigen.found() and g_ir_dep.found()
    subdir('vapi')
endif
