GO_EASY_ON_ME = 1
ARCHS = arm64
OS := $(shell uname)
ifeq ($(OS),Darwin)
  TARGET = iphone:12.1:9.2
  ARCHS += arm64e
endif

ADDITIONAL_OBJCFLAGS = -fobjc-arc
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Slices
Slices_FILES = SLViewController.m SLWindow.m Model/SSKeychain/SSKeychain.m Model/GameCenterAccountManager.mm Model/AppGroupSlicer.mm Tweak.xm Model/RawSlicer.mm Model/Slicer.mm Model/FolderMigrator.mm Model/SliceSetting.mm
Slices_FRAMEWORKS = Security UIKit
Slices_PRIVATE_FRAMEWORKS = GameKit BackBoardServices MobileCoreServices FrontBoard AppSupport
Slices_LIBRARIES = MobileGestalt applist rocketbootstrap

include $(THEOS)/makefiles/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += slicespreferences
include $(THEOS)/makefiles/aggregate.mk
