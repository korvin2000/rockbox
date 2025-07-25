#             __________               __   ___.
#   Open      \______   \ ____   ____ |  | _\_ |__   _______  ___
#   Source     |       _//  _ \_/ ___\|  |/ /| __ \ /  _ \  \/  /
#   Jukebox    |    |   (  <_> )  \___|    < | \_\ (  <_> > <  <
#   Firmware   |____|_  /\____/ \___  >__|_ \|___  /\____/__/\_ \
#                     \/            \/     \/    \/            \/
# $Id$
#

# single-file plugins:
is_app_build =
ifdef APP_TYPE
ifneq ($(APP_TYPE),sdl-sim)
    is_app_build = yes
endif
endif

ifdef is_app_build
PLUGINS_SRC = $(call preprocess, $(APPSDIR)/plugins/SOURCES.app_build)
else
PLUGINS_SRC = $(call preprocess, $(APPSDIR)/plugins/SOURCES)
endif
OTHER_SRC += $(PLUGINS_SRC)
ROCKS1 := $(PLUGINS_SRC:.c=.rock)
ROCKS1 := $(call full_path_subst,$(ROOTDIR)/%,$(BUILDDIR)/%,$(ROCKS1))

ROCKS := $(ROCKS1)

ROCKS1 := $(ROCKS1:%.lua=)

# libplugin.a
PLUGINLIB := $(BUILDDIR)/apps/plugins/libplugin.a
PLUGINLIB_SRC = $(call preprocess, $(APPSDIR)/plugins/lib/SOURCES)
OTHER_SRC += $(PLUGINLIB_SRC)

PLUGINLIB_OBJ := $(PLUGINLIB_SRC:.c=.o)
PLUGINLIB_OBJ := $(PLUGINLIB_OBJ:.S=.o)
PLUGINLIB_OBJ := $(call full_path_subst,$(ROOTDIR)/%,$(BUILDDIR)/%,$(PLUGINLIB_OBJ))

### build data / rules
ifndef APP_TYPE
CONFIGFILE := $(FIRMDIR)/export/config/$(MODELNAME).h
PLUGIN_LDS := $(APPSDIR)/plugins/plugin.lds
PLUGINLINK_LDS := $(BUILDDIR)/apps/plugins/plugin.link
OVERLAYREF_LDS := $(BUILDDIR)/apps/plugins/overlay_ref.link
endif
OTHER_SRC += $(ROOTDIR)/apps/plugins/plugin_crt0.c
PLUGIN_CRT0 := $(BUILDDIR)/apps/plugins/plugin_crt0.o
# multifile plugins (subdirs):
ifdef is_app_build
PLUGINSUBDIRS := $(call preprocess, $(APPSDIR)/plugins/SUBDIRS.app_build)
else
PLUGINSUBDIRS := $(call preprocess, $(APPSDIR)/plugins/SUBDIRS)
endif

PLUGIN_LIBS := $(PLUGINLIB) $(PLUGINBITMAPLIB) $(SETJMPLIB) $(FIXEDPOINTLIB)

# include <dir>.make from each subdir (yay!)
$(foreach dir,$(PLUGINSUBDIRS),$(eval include $(dir)/$(notdir $(dir)).make))

OTHER_INC += -I$(APPSDIR)/plugins -I$(APPSDIR)/plugins/lib

# special compile flags for plugins:
PLUGINFLAGS = -I$(APPSDIR)/plugins -DPLUGIN $(CFLAGS)

# single-file plugins depend on their respective .o
$(ROCKS1): $(BUILDDIR)/%.rock: $(BUILDDIR)/%.o

# dependency for all plugins
$(ROCKS): $(APPSDIR)/plugin.h $(PLUGINLINK_LDS) $(PLUGIN_LIBS) $(PLUGIN_CRT0)

$(PLUGINLIB): $(PLUGINLIB_OBJ)
	$(SILENT)$(shell rm -f $@)
	$(call PRINTS,AR $(@F))$(AR) rcs $@ $^ >/dev/null

$(PLUGINLINK_LDS): $(PLUGIN_LDS) $(CONFIGFILE)
	$(call PRINTS,PP $(@F))
	$(shell mkdir -p $(dir $@))
	$(call preprocess2file,$<,$@,-DLOADADDRESS=$(LOADADDRESS))

$(OVERLAYREF_LDS): $(PLUGIN_LDS)
	$(call PRINTS,PP $(@F))
	$(shell mkdir -p $(dir $@))
	$(call preprocess2file,$<,$@,-DOVERLAY_OFFSET=0)

$(BUILDDIR)/credits.raw credits.raw: $(DOCSDIR)/CREDITS
	$(call PRINTS,Create credits.raw)perl $(APPSDIR)/plugins/credits.pl < $< > $(BUILDDIR)/$(@F)

$(BUILDDIR)/apps/plugins/open_plugins.opx:
	$(call PRINTS,MK open_plugins.opx) touch $< $(BUILDDIR)/apps/plugins/open_plugins.opx

$(BUILDDIR)/apps/plugins/open_plugins.rock: $(BUILDDIR)/apps/plugins/open_plugins.opx

# special dependencies
$(BUILDDIR)/apps/plugins/wav2wv.rock: $(RBCODEC_BLD)/codecs/libwavpack.a $(PLUGIN_LIBS)

# Do not use '-ffunction-sections' and '-fdata-sections' when compiling sdl-sim
ifeq ($(findstring sdl-sim, $(APP_TYPE)), sdl-sim)
    PLUGINLIBFLAGS = $(PLUGINFLAGS)
else
    PLUGINLIBFLAGS = $(PLUGINFLAGS) -ffunction-sections -fdata-sections
endif

ROOT_PLUGINSLIB_DIR := $(ROOTDIR)/apps/plugins/lib
BUILD_PLUGINSLIB_DIR := $(BUILDDIR)/apps/plugins/lib

# action_helper #
ACTION_REQ := $(addprefix $(ROOT_PLUGINSLIB_DIR)/,action_helper.pl action_helper.h) \
				$(BUILD_PLUGINSLIB_DIR)/pluginlib_actions.o

# special rule for generating and compiling action_helper
$(BUILD_PLUGINSLIB_DIR)/action_helper.o: $(ACTION_REQ)
	$(SILENT)mkdir -p $(dir $@)
	$(call PRINTS,GEN $(@F))$(CC) $(PLUGINFLAGS) $(INCLUDES) -E -P \
		$(ROOT_PLUGINSLIB_DIR)/pluginlib_actions.h - < /dev/null | $< > $(basename $@).c
	$(call PRINTS,CC $(subst $(ROOTDIR)/,,$<))$(CC) -I$(ROOT_PLUGINSLIB_DIR) \
		$(PLUGINLIBFLAGS) -c $(basename $@).c -o $@

# button_helper #
BUTTON_REQ := $(addprefix $(ROOT_PLUGINSLIB_DIR)/,button_helper.pl button_helper.h) \
				$(BUILD_PLUGINSLIB_DIR)/action_helper.o

# special rule for generating and compiling button_helper
$(BUILD_PLUGINSLIB_DIR)/button_helper.o: $(BUTTON_REQ) $(ROOTDIR)/firmware/export/button.h
	$(SILENT)mkdir -p $(dir $@)
	$(call PRINTS,GEN $(@F))$(CC) $(PLUGINFLAGS) $(INCLUDES) -dM -E -P \
		$(addprefix -include ,button-target.h button.h) - < /dev/null | $< > $(basename $@).c
	$(call PRINTS,CC $(subst $(ROOTDIR)/,,$<))$(CC) -I$(ROOT_PLUGINSLIB_DIR) \
		$(PLUGINLIBFLAGS) -c $(basename $@).c -o $@

# special pattern rule for compiling plugin lib (with function and data sections)
$(BUILD_PLUGINSLIB_DIR)/%.o: $(ROOT_PLUGINSLIB_DIR)/%.c
	$(SILENT)mkdir -p $(dir $@)
	$(call PRINTS,CC $(subst $(ROOTDIR)/,,$<))$(CC) -I$(dir $<) $(PLUGINLIBFLAGS) -c $< -o $@

# special pattern rule for compiling plugins with extra flags
$(BUILDDIR)/apps/plugins/%.o: $(ROOTDIR)/apps/plugins/%.c
	$(SILENT)mkdir -p $(dir $@)
	$(call PRINTS,CC $(subst $(ROOTDIR)/,,$<))$(CC) -I$(dir $<) $(PLUGINFLAGS) -c $< -o $@

ifdef APP_TYPE
 PLUGINLDFLAGS = $(SHARED_LDFLAGS) -Wl,-Map,$*.map
 PLUGINFLAGS += $(SHARED_CFLAGS) # <-- from Makefile
else
 PLUGINLDFLAGS = -T$(PLUGINLINK_LDS) -Wl,--gc-sections -Wl,-Map,$*.map
 OVERLAYLDFLAGS = -T$(OVERLAYREF_LDS) -Wl,--gc-sections -Wl,-Map,$*.refmap
endif
PLUGINLDFLAGS += $(GLOBAL_LDOPTS)

$(BUILDDIR)/%.rock:
	$(call PRINTS,LD $(@F))$(CC) $(PLUGINFLAGS) -o $(BUILDDIR)/$*.elf \
		$(filter %.o, $^) \
		$(filter %.a, $+) \
		$(LDGCC720) $(PLUGINLDFLAGS)
	$(SILENT)$(call objcopy,$(BUILDDIR)/$*.elf,$@)

$(BUILDDIR)/apps/plugins/%.lua: $(ROOTDIR)/apps/plugins/%.lua
	$(call PRINTS,CP $(subst $(ROOTDIR)/,,$<))cp $< $(BUILDDIR)/apps/plugins/

$(BUILDDIR)/%.refmap: $(APPSDIR)/plugin.h $(OVERLAYREF_LDS) $(PLUGIN_LIBS) $(PLUGIN_CRT0)
	$(call PRINTS,LD $(@F))$(CC) $(PLUGINFLAGS) -o /dev/null \
		$(filter %.o, $^) \
		$(filter %.a, $+) \
		$(LDGCC720) $(OVERLAYLDFLAGS)
