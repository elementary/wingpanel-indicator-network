i18n.merge_file(
    input: 'network.metainfo.xml.in',
    output: gettext_name + '.metainfo.xml',
    po_dir: meson.project_source_root() / 'po' / 'extra',
    type: 'xml',
    install: true,
    install_dir: get_option('datadir') / 'metainfo',
)

configure_file(
    input: 'network.policy.in',
    output: gettext_name + '.policy',
    configuration: config_data,
    install_dir: polkit_dep.get_variable('policydir', pkgconfig_define: ['prefix', prefix])
)
