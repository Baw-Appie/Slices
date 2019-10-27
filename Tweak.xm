#import <substrate.h>
#import "Model/Slicer.h"
#import "Headers/SpringBoardHeaders.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <rocketbootstrap/rocketbootstrap.h>
#import "./SLWindow.h"

#define PREFERENCE_IDENTIFIER CFSTR("com.subdiox.slicespreferences")
#define ENABLED_KEY CFSTR("isEnabled")
#define SHOW_NEW_SLICE_OPTION_KEY CFSTR("showNewSliceOption")
#define WELCOME_MESSAGE_KEY CFSTR("hasSeenWelcomeMessage")
#define VERSION_KEY CFSTR("version")

#define CURRENT_SETTINGS_VERSION 1

static BOOL isEnabled, hasSeenWelcomeMessage, showNewSliceOption, use3DTouch;
static NSInteger version;

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
	%orig;

	CPDistributedMessagingCenter * messagingCenter = [CPDistributedMessagingCenter centerNamed:@"com.rpgfarm.slices"];
	rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
	[messagingCenter runServerOnCurrentThread];
	[messagingCenter registerForMessageName:@"selectSlices" target:self selector:@selector(selectSlices:withUserInfo:)];

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.subdiox.slicespreferences.plist"];
	if (!prefs) {
		prefs = [[NSMutableDictionary alloc] init];
	}

	[prefs writeToFile:@"/var/mobile/Library/Preferences/com.subdiox.slicespreferences.plist" atomically:YES];

	[SLWindow sharedInstance];
}

%new
-(void)selectSlices:(NSString *)name withUserInfo:(NSDictionary *)userInfo {
	HBLogDebug(@"Request Receviedjeinovaanscansc9unhauwdjh9poaunhxi!");
	SBApplication *application = [[NSClassFromString(@"SBApplicationController") sharedInstance] applicationWithBundleIdentifier:userInfo[@"application"]];
	Slicer *slicer = [[Slicer alloc] initWithApplication:application controller:[%c(SBApplicationController) sharedInstance]];
	NSString *currentSlice = slicer.currentSlice;
	HBLogDebug(@"Request %@!", currentSlice);
	NSString *actionSheetTitle;
	if (currentSlice.length > 0)
		actionSheetTitle = [NSString stringWithFormat:@"%@: %@", Localize(@"Current Slice"), currentSlice];
	else if (slicer.slices.count < 1)
		actionSheetTitle = Localize(@"All existing data will be copied into the new slice.");
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:actionSheetTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[SLWindow sharedInstance].touchInjection = true;
	NSArray *slices = slicer.slices;
	for (NSString *slice in slices) {
		[alert addAction:[UIAlertAction actionWithTitle:slice style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			Slicer *slicer = [[Slicer alloc] initWithApplication:application controller:[%c(SBApplicationController) sharedInstance]];
			[slicer switchToSlice:action.title completionHandler:^(BOOL success) {
				[[UIApplication sharedApplication] launchApplicationWithIdentifier:[application bundleIdentifier] suspended: NO];
			}];
			[SLWindow sharedInstance].touchInjection = false;
		}]];
	}
	if (showNewSliceOption) {
		[alert addAction:[UIAlertAction actionWithTitle:Localize(@"New Slice") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localize(@"New Slice") message:Localize(@"Enter the slice name") preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction: [UIAlertAction actionWithTitle:Localize(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
			[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
				textField.placeholder = @"slice name";
			}];
			[alert addAction:[UIAlertAction actionWithTitle:Localize(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
				NSString *sliceName = alert.textFields[0].text;
				Slicer *slicer = [[Slicer alloc] initWithApplication:application controller:[%c(SBApplicationController) sharedInstance]];
				BOOL created = [slicer createSlice:sliceName];
				if (created) {
					[[UIApplication sharedApplication] launchApplicationWithIdentifier:[application bundleIdentifier] suspended: NO];
				}
			}]];
			[[SLWindow sharedInstance].rootViewController presentViewController:alert animated:YES completion:nil];
			[SLWindow sharedInstance].touchInjection = false;
		}]];
	}
	[alert addAction:[UIAlertAction actionWithTitle:Localize(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		[SLWindow sharedInstance].touchInjection = false;
	}]];
	[[SLWindow sharedInstance].rootViewController presentViewController:alert animated:YES completion:nil];
}
%end

#define forceTouchAvailable ([[[[UIApplication sharedApplication] keyWindow] traitCollection] forceTouchCapability] == UIForceTouchCapabilityAvailable)

%hook SBUIController
-(void)activateApplication:(id)arg1 fromIcon:(id)arg2 location:(long long)arg3 activationSettings:(id)arg4 actions:(id)arg5 {
	if((isEnabled && !use3DTouch && forceTouchAvailable) || (isEnabled && !forceTouchAvailable)) {
		SBApplication *application = arg1;
		BOOL isUserApplication = NO;

		if ([application respondsToSelector:@selector(dataContainerPath)]) {
			isUserApplication = [[application dataContainerPath] hasPrefix:@"/private/var/mobile/Containers/Data/Application/"];
		} else {
			isUserApplication = [[application info].dataContainerURL.path hasPrefix:@"/private/var/mobile/Containers/Data/Application/"];
		}

		if (isUserApplication) {
			Slicer *slicer = [[Slicer alloc] initWithApplication:arg1 controller:[%c(SBApplicationController) sharedInstance]];
			HBLogDebug(@"Slices: slicer=%@", slicer);
			BOOL askOnTouch = slicer.askOnTouch;

			if (askOnTouch) {
				CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:@"com.rpgfarm.slices"];
				rocketbootstrap_distributedmessagingcenter_apply(c);
				NSDictionary * message = [NSDictionary dictionaryWithObjectsAndKeys:[application bundleIdentifier], @"application", nil];
				[c sendMessageName:@"selectSlices" userInfo:message];
			} else {
				[slicer switchToSlice:slicer.defaultSlice completionHandler:^(BOOL success) {
					%orig;
				}];
			}
		} else {
			%orig;
		}
	} else %orig;
}
%end

%hook SBUIIconForceTouchViewController
-(void)_presentAnimated:(BOOL)arg1 withCompletionHandler:(void (^)())arg2 {
	SBUIIconForceTouchIconViewWrapperView *wrapperView = MSHookIvar<SBUIIconForceTouchIconViewWrapperView *>(self, "_iconViewWrapperViewAbove");
  HBLogDebug(@"Welcome 3D Touch! %@", wrapperView.iconView);
  NSString *bundle;
  SBApplication *application;
  if([wrapperView.iconView isKindOfClass:[objc_getClass("SearchUIAppIconButton") class]]) {
    bundle = [(SFSearchResult *)[(SearchUIAppIconButton *)[wrapperView iconView] result] identifier];
    application = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:bundle];
  } else {
    bundle = [wrapperView.iconView.icon applicationBundleID];
    application = [wrapperView.iconView.icon application];
  }
	if(bundle && [wrapperView respondsToSelector:@selector(iconView)]) {
		if (!isEnabled || !use3DTouch) {
			HBLogDebug(@"Running orig");
			return %orig;
		} else {
			BOOL isUserApplication = NO;
			if ([application respondsToSelector:@selector(dataContainerPath)]) {
				isUserApplication = [[application dataContainerPath] hasPrefix:@"/private/var/mobile/Containers/Data/Application/"];
			} else {
				isUserApplication = [[application info].dataContainerURL.path hasPrefix:@"/private/var/mobile/Containers/Data/Application/"];
			}
			if(isUserApplication) {
				Slicer *slicer = [[Slicer alloc] initWithApplication:application controller:[%c(SBApplicationController) sharedInstance]];
				HBLogDebug(@"Slices: slicer=%@", slicer);
				BOOL askOnTouch = slicer.askOnTouch;
				NSString *currentSlice = slicer.currentSlice;
				if (askOnTouch) {
					arg2();
					[self dismissAnimated:true withCompletionHandler:nil];
					HBLogDebug(@"Request to SpringBoard...");
					CPDistributedMessagingCenter *c = [CPDistributedMessagingCenter centerNamed:@"com.rpgfarm.slices"];
					rocketbootstrap_distributedmessagingcenter_apply(c);
					NSDictionary * message = [NSDictionary dictionaryWithObjectsAndKeys:bundle, @"application", nil];
					[c sendMessageName:@"selectSlices" userInfo:message];
				} else {
					if([currentSlice isEqualToString:slicer.defaultSlice]) {
						HBLogDebug(@"switchToSlice already done!");
						%orig;
					} else {
						HBLogDebug(@"try switchToSlice!");
						[slicer switchToSlice:slicer.defaultSlice completionHandler:^(BOOL success) {
							HBLogDebug(@"switchToSlice Done!");
							%orig;
						}];
					}
				}
			} else {
				%orig;
			}
		}
	} else {
		HBLogDebug(@"No BundleID");
		%orig;
	}
}
%end

static void loadSettings() {
	CFPreferencesAppSynchronize(PREFERENCE_IDENTIFIER);

	Boolean keyExists;
	isEnabled = CFPreferencesGetAppBooleanValue(ENABLED_KEY, PREFERENCE_IDENTIFIER, &keyExists);
	isEnabled = (isEnabled || !keyExists);

	use3DTouch = CFPreferencesGetAppBooleanValue(CFSTR("use3DTouch"), PREFERENCE_IDENTIFIER, &keyExists);
	use3DTouch = (use3DTouch || !keyExists);

	showNewSliceOption = CFPreferencesGetAppBooleanValue(SHOW_NEW_SLICE_OPTION_KEY, PREFERENCE_IDENTIFIER, &keyExists);
	showNewSliceOption = (showNewSliceOption || !keyExists);

	hasSeenWelcomeMessage = CFPreferencesGetAppBooleanValue(WELCOME_MESSAGE_KEY, PREFERENCE_IDENTIFIER, &keyExists);

	version = CFPreferencesGetAppIntegerValue(VERSION_KEY, PREFERENCE_IDENTIFIER, &keyExists);
}

static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  loadSettings();
}

%ctor {
	//listen for changes in settings
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChanged, CFSTR("com.subdiox.slicespreferences/settingsChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	loadSettings();
}
