#line 1 "Tweak.xm"
#import <substrate.h>
#import "Model/Slicer.h"
#import "Headers/SpringBoardHeaders.h"

#define PREFERENCE_IDENTIFIER CFSTR("com.subdiox.slicespreferences")
#define ENABLED_KEY CFSTR("isEnabled")
#define SHOW_NEW_SLICE_OPTION_KEY CFSTR("showNewSliceOption")
#define VERSION_KEY CFSTR("version")

#define CURRENT_SETTINGS_VERSION 1

static BOOL isEnabled, showNewSliceOption;
static NSInteger version;


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class SBIconView; @class SpringBoard; @class SBApplicationController; 
static void (*_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$_ungrouped$SBIconView$touchesBegan$withEvent$)(_LOGOS_SELF_TYPE_NORMAL SBIconView* _LOGOS_SELF_CONST, SEL, NSSet *, UIEvent *); static void _logos_method$_ungrouped$SBIconView$touchesBegan$withEvent$(_LOGOS_SELF_TYPE_NORMAL SBIconView* _LOGOS_SELF_CONST, SEL, NSSet *, UIEvent *); static SBApplication * _logos_method$_ungrouped$SBIconView$application(_LOGOS_SELF_TYPE_NORMAL SBIconView* _LOGOS_SELF_CONST, SEL); 
static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBApplicationController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBApplicationController"); } return _klass; }
#line 15 "Tweak.xm"

static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id application) {
	_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$(self, _cmd, application);

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.subdiox.slicespreferences.plist"];
	if (!prefs) {
		prefs = [[NSMutableDictionary alloc] init];
	}

	[prefs writeToFile:@"/var/mobile/Library/Preferences/com.subdiox.slicespreferences.plist" atomically:YES];

	int rawVersion = CURRENT_SETTINGS_VERSION;
	CFNumberRef versionReference = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &rawVersion);
	CFPreferencesSetAppValue(VERSION_KEY, versionReference, PREFERENCE_IDENTIFIER);
}



static void _logos_method$_ungrouped$SBIconView$touchesBegan$withEvent$(_LOGOS_SELF_TYPE_NORMAL SBIconView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSSet * touches, UIEvent * event) {
	if (!isEnabled) {
		_logos_orig$_ungrouped$SBIconView$touchesBegan$withEvent$(self, _cmd, touches, event);
	} else {
		BOOL isGrabbed = [self isGrabbed];
		BOOL isEditing = [self isEditing];
		BOOL isDragging = NO;
		if ([self respondsToSelector:@selector(isDragging)]) {
			isDragging = [self isDragging];
		}
		id<SBIconViewDelegate> delegate = [self delegate];
		BOOL respondsToIconTapped = [delegate respondsToSelector:@selector(iconTapped:)];

		SBApplication *application = [self application];
		BOOL isUserApplication = NO;

		if ([application respondsToSelector:@selector(dataContainerPath)]) {
			isUserApplication = [[application dataContainerPath] hasPrefix:@"/private/var/mobile/Containers/Data/Application/"];
		} else {
			isUserApplication = [[application info].dataContainerURL.path hasPrefix:@"/private/var/mobile/Containers/Data/Application/"];
		}

		BOOL wouldHaveLaunched = !isGrabbed && !isDragging && [self _delegateTapAllowed] && !isEditing && respondsToIconTapped;
		if (wouldHaveLaunched && isUserApplication) {
			Slicer *slicer = [[Slicer alloc] initWithApplication:[self application] controller:[_logos_static_class_lookup$SBApplicationController() sharedInstance]];
			BOOL askOnTouch = slicer.askOnTouch;

			if (askOnTouch) {
				NSString *actionSheetTitle;
				NSString *currentSlice = slicer.currentSlice;
				if (currentSlice.length > 0)
					actionSheetTitle = [NSString stringWithFormat:@"%@: %@", Localize(@"Current Slice"), currentSlice];
				else if (slicer.slices.count < 1)
					actionSheetTitle = Localize(@"All existing data will be copied into the new slice.");

				UIAlertController *alert = [UIAlertController alertControllerWithTitle:actionSheetTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
				
				NSArray *slices = slicer.slices;
				for (NSString *slice in slices) {
					[alert addAction:[UIAlertAction actionWithTitle:slice style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
						
						Slicer *slicer = [[Slicer alloc] initWithApplication:[self application] controller:[_logos_static_class_lookup$SBApplicationController() sharedInstance]];
						[slicer switchToSlice:action.title completionHandler:^(BOOL success) {
							
							[delegate iconTapped:self];
						}];
					}]];
				}
				if (showNewSliceOption) {
					[alert addAction:[UIAlertAction actionWithTitle:Localize(@"New Slice") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
						
						Slicer *slicer = [[Slicer alloc] initWithApplication:[self application] controller:[_logos_static_class_lookup$SBApplicationController() sharedInstance]];
						
						UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localize(@"New Slice") message:Localize(@"Enter the slice name") preferredStyle:UIAlertControllerStyleAlert];
						[alert addAction: [UIAlertAction actionWithTitle:Localize(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
						}]];
						[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
							textField.text = [NSString stringWithFormat:Localize(@"Slice %d"), slicer.slices.count + 1];
							textField.placeholder = Localize(@"Slice Name");
						}];
						[alert addAction:[UIAlertAction actionWithTitle:Localize(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
							NSString *sliceName = alert.textFields[0].text;
							
							
							BOOL created = [slicer createSlice:sliceName];

							
							if (created) {
								[delegate iconTapped:self];
							}
						}]];
						alert.popoverPresentationController.sourceView = self;
						[[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
					}]];
				}
				[alert addAction: [UIAlertAction actionWithTitle:Localize(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
				}]];
				alert.popoverPresentationController.sourceView = self;
				[[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
			} else {
				[slicer switchToSlice:slicer.defaultSlice completionHandler:^(BOOL success) {
					_logos_orig$_ungrouped$SBIconView$touchesBegan$withEvent$(self, _cmd, touches, event);
				}];
			}
		} else {
			_logos_orig$_ungrouped$SBIconView$touchesBegan$withEvent$(self, _cmd, touches, event);
		}
	}
}


static SBApplication * _logos_method$_ungrouped$SBIconView$application(_LOGOS_SELF_TYPE_NORMAL SBIconView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
	return [self.icon application];
}



static void loadSettings() {
	CFPreferencesAppSynchronize(PREFERENCE_IDENTIFIER);
	
	Boolean keyExists;
	isEnabled = CFPreferencesGetAppBooleanValue(ENABLED_KEY, PREFERENCE_IDENTIFIER, &keyExists);
	isEnabled = (isEnabled || !keyExists);

	showNewSliceOption = CFPreferencesGetAppBooleanValue(SHOW_NEW_SLICE_OPTION_KEY, PREFERENCE_IDENTIFIER, &keyExists);
	showNewSliceOption = (showNewSliceOption || !keyExists);

	version = CFPreferencesGetAppIntegerValue(VERSION_KEY, PREFERENCE_IDENTIFIER, &keyExists);
}

static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  loadSettings();
}

static __attribute__((constructor)) void _logosLocalCtor_d0f2e29d(int __unused argc, char __unused **argv, char __unused **envp) {
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChanged, CFSTR("com.subdiox.slicespreferences/settingsChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	loadSettings();
}
static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$SpringBoard = objc_getClass("SpringBoard"); MSHookMessageEx(_logos_class$_ungrouped$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$);Class _logos_class$_ungrouped$SBIconView = objc_getClass("SBIconView"); MSHookMessageEx(_logos_class$_ungrouped$SBIconView, @selector(touchesBegan:withEvent:), (IMP)&_logos_method$_ungrouped$SBIconView$touchesBegan$withEvent$, (IMP*)&_logos_orig$_ungrouped$SBIconView$touchesBegan$withEvent$);{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(SBApplication *), strlen(@encode(SBApplication *))); i += strlen(@encode(SBApplication *)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$SBIconView, @selector(application), (IMP)&_logos_method$_ungrouped$SBIconView$application, _typeEncoding); }} }
#line 152 "Tweak.xm"
