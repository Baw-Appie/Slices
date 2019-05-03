THEOS_DEVICE_IP = 192.168.11.8
THEOS_DEVICE_PORT = 22

ARCHS = armv7 armv7s arm64 arm64e
ADDITIONAL_OBJCFLAGS = -fobjc-arc
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Slices
Slices_FILES = Model/SSKeychain/SSKeychain.m Model/GameCenterAccountManager.mm Model/AppGroupSlicer.mm Tweak.xm Model/RawSlicer.mm Model/Slicer.mm Model/FolderMigrator.mm Model/SliceSetting.mm
Slices_FRAMEWORKS = Security UIKit
Slices_PRIVATE_FRAMEWORKS = GameKit BackBoardServices MobileCoreServices FrontBoard
Slices_LIBRARIES = MobileGestalt applist

include $(THEOS)/makefiles/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += slicespreferences
include $(THEOS)/makefiles/aggregate.mk
