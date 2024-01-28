i18n.merge_file(
    input: 'network.metainfo.xml.in',
    output: 'io.elementary.wingpanel.network.metainfo.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
)

configure_file(
    input: 'network.policy.in',
    output: 'io.elementary.wingpanel.network.policy',
    configuration: config_data,
    install_dir: polkit_dep.get_pkgconfig_variable('policydir', define_variable: ['prefix', prefix])
)
