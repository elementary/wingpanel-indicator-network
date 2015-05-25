libexec_PROGRAMS = indicator-network-service
indicatordir = $(INDICATORDIR)
indicator_LTLIBRARIES = libnetwork.la

indicator_network_service_SOURCES = 	\
	config.vapi \
	indicator3-0.4.vapi \
	libnm-gtk.vapi \
	rfkill.vala \
	indicator-network-service.vala

indicator_network_service_VALAFLAGS = \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gtk+-3.0 \
	--pkg Dbusmenu-0.4 \
	--pkg libnm-glib \
	--pkg libnm-util


indicator_network_service_CFLAGS = \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	-DLOCALE_DIR=\"$(datadir)/locale\" \
	$(INDICATOR_NETWORK_SERVICE_CFLAGS)

indicator_network_service_LDADD = \
	$(INDICATOR_NETWORK_SERVICE_LIBS)

libnetwork_la_SOURCES = 	\
	config.vapi \
	indicator3-0.4.vapi \
	indicator-network.vala \
	libido3-0.1.vapi

libnetwork_la_VALAFLAGS = \
	--pkg posix \
	--pkg glib-2.0 \
	--pkg gtk+-3.0 \
	--pkg Dbusmenu-0.4 \
	--pkg DbusmenuGtk3-0.4

libnetwork_la_CFLAGS = \
	$(INDICATOR_NETWORK_CFLAGS)

libnetwork_la_LIBADD = \
	$(INDICATOR_NETWORK_LIBS)

libnetwork_la_LDFLAGS = \
	-module -avoid-version

CLEANFILES = \
	$(patsubst %.vala,%.c,$(filter %.vala, $(SOURCES))) \
	*_vala.stamp
