DEBUG = 0
FINALPACKAGE = 1
ARCHS = arm64
TARGET := iphone:clang:16.5:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = OnlyGalsTV
$(TWEAK_NAME)_FILES = Tweak.x

include $(THEOS_MAKE_PATH)/tweak.mk
