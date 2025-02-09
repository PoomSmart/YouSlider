TARGET := iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = YouTube
ARCHS = arm64
PACKAGE_VERSION = 1.1.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YouSlider

$(TWEAK_NAME)_FILES = Tweak.x Settings.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_LIBRARIES = colorpicker
$(TWEAK_NAME)_EXTRA_FRAMEWORKS = Alderis

include $(THEOS_MAKE_PATH)/tweak.mk
