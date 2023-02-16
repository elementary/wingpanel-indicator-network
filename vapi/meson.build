g_ir_dep = dependency('gobject-introspection-1.0')
gir_dir = g_ir_dep.get_pkgconfig_variable('girdir')

libnm_target = custom_target('libnm',
    command: [
        vapigen,
        gir_dir / 'NM-1.0.gir',
        '--library=libnm',
        '--pkg=gio-2.0',
        '--directory=@0@'.format(meson.current_build_dir()),
        '--metadatadir=@0@'.format(meson.current_source_dir()),
    ],
    output: 'libnm.vapi'
)

libnma_target = custom_target('libnma',
    command: [
        vapigen,
        gir_dir / 'NMA-1.0.gir',
        '--library=libnma',
        '--pkg=libnm',
        '--pkg=gtk+-3.0',
        '--directory=@0@'.format(meson.current_build_dir()),
        '--metadatadir=@0@'.format(meson.current_source_dir()),
        '--vapidir=@0@'.format(meson.current_build_dir()),
    ],
    depends: libnm_target,
    output: 'libnma.vapi'
)
