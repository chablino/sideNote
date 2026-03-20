THEOS_PACKAGE_SCHEME = rootless

TARGET = iphone:clang:18.4:15.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SideNote

SideNote_FILES = Tweak.x SideNotePanel.m SideNotePassthroughView.m SideNotePassthroughWindow.m SideNoteStorage.m
SideNote_FRAMEWORKS = UIKit CoreGraphics Foundation
SideNote_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
