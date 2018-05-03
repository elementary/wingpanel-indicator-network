project('network', 'vala', 'c')

gettext_name = meson.project_name() + '-indicator'
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_name), language:'c')

add_project_arguments(
    '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
    language: 'vala'
)

wingpanel_dep = dependency('wingpanel-2.0')

shared_module(
    meson.project_name(),
    'src/Indicator.vala',
    'src/Utils.vala',
    'src/common/rfkill.vala',
    'src/common/Widgets/AbstractEtherInterface.vala',
    'src/common/Widgets/AbstractModemInterface.vala',
    'src/common/Widgets/AbstractVpnInterface.vala',
    'src/common/Widgets/AbstractWifiInterface.vala',
    'src/common/Widgets/NMVisualizer.vala',
    'src/common/Widgets/VpnMenuItem.vala',
    'src/common/Widgets/WidgetNMInterface.vala',
    'src/common/Widgets/WifiMenuItem.vala',
    'src/Widgets/DisplayWidget.vala',
    'src/Widgets/EtherInterface.vala',
    'src/Widgets/ModemInterface.vala',
    'src/Widgets/VpnInterface.vala',
    'src/Widgets/WifiInterface.vala',
    'src/Widgets/PopoverWidget.vala',
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('libnm'),
        dependency('libnma'),
        meson.get_compiler('vala').find_library('posix'),
        wingpanel_dep
    ],
    install: true,
    install_dir : wingpanel_dep.get_pkgconfig_variable('indicatorsdir')
)

subdir('po')
