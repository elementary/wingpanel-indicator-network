project(
    'network',
    'vala', 'c',
    version: '2.3.4'
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

shared_module(
    meson.project_name(),
    config_file,
    'src/Indicator.vala',
    'src/Utils.vala',
    'src/common/rfkill.vala',
    'src/common/Widgets/VpnMenuItem.vala',
    'src/common/Widgets/WidgetNMInterface.vala',
    'src/common/Widgets/WifiMenuItem.vala',
    'src/Widgets/DisplayWidget.vala',
    'src/Widgets/EtherInterface.vala',
    'src/Widgets/ModemInterface.vala',
    'src/Widgets/VpnInterface.vala',
    'src/Widgets/WifiInterface.vala',
    'src/Widgets/PopoverWidget.vala',
    gresource,
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('libnm', version: '>=1.20.6'),
        dependency('libnma'),
        meson.get_compiler('vala').find_library('posix'),
        wingpanel_dep
    ],
    install: true,
    install_dir : wingpanel_indicatorsdir
)

subdir('data')
subdir('po')
