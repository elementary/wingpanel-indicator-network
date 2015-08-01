find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0 libnm-glib libnm-gtk libnm-util wingpanel-2.0 granite)

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.22.0" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
  Indicator.vala
  Utils.vala
  Widgets/DisplayWidget.vala
  Widgets/PopoverWidget.vala
  Widgets/AutomaticScrollBox.vala
  Widgets/EtherInterface.vala
  Widgets/WifiInterface.vala
  Widgets/WidgetNMInterface.vala
  Widgets/WifiMenuItem.vala
  Widgets/common/NMVisualizer.vala
  Services/SettingsManager.vala
  ${CMAKE_CURRENT_BINARY_DIR}/config.vala
  rfkill.vala

PACKAGES
  wingpanel-2.0
  granite
  libnm-glib
  libnm-util
  posix
CUSTOM_VAPIS
  libnm-gtk.vapi
OPTIONS
  --thread
)

add_library (${CMAKE_PROJECT_NAME} MODULE ${VALA_C})
target_link_libraries(${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES})

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} DESTINATION ${PKGDATADIR})
