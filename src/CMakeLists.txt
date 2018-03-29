find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0 libnm libnma wingpanel-2.0 granite)

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.22.0" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
  Indicator.vala
  Widgets/DisplayWidget.vala
  Widgets/PopoverWidget.vala
  Widgets/EtherInterface.vala
  Widgets/VpnInterface.vala
  Widgets/WifiInterface.vala
  Widgets/ModemInterface.vala
  common/Utils.vala
  common/Widgets/WifiMenuItem.vala
  common/Widgets/VpnMenuItem.vala
  common/Widgets/NMVisualizer.vala
  common/Widgets/WidgetNMInterface.vala
  Services/SettingsManager.vala
  ${CMAKE_CURRENT_BINARY_DIR}/config.vala
  common/rfkill.vala
  common/Widgets/AbstractWifiInterface.vala
  common/Widgets/AbstractVpnInterface.vala
  common/Widgets/AbstractEtherInterface.vala
  common/Widgets/AbstractModemInterface.vala

PACKAGES
  wingpanel-2.0
  granite
  posix
  libnm
  libnma
OPTIONS
  --thread
  --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

add_library (${CMAKE_PROJECT_NAME} MODULE ${VALA_C})
target_link_libraries(${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES})

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} DESTINATION ${PKGDATADIR})
