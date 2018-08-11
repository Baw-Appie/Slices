#import <substrate.h>
#import "Model/Slicer.h"
#import "Headers/SpringBoardHeaders.h"

#define PREFERENCE_IDENTIFIER CFSTR("com.subdiox.slicespreferences")
#define ENABLED_KEY CFSTR("isEnabled")
#define SHOW_NEW_SLICE_OPTION_KEY CFSTR("showNewSliceOption")
#define WELCOME_MESSAGE_KEY CFSTR("hasSeenWelcomeMessage")
#define VERSION_KEY CFSTR("version")

#define CURRENT_SETTINGS_VERSION 1

static BOOL isEnabled, hasSeenWelcomeMessage, showNewSliceOption;
static NSInteger version;

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
	%orig;

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.subdiox.slicespreferences.plist"];
	if (!prefs) {
		prefs = [[NSMutableDictionary alloc] init];
	}

	[prefs setObject:[NSNumber numberWithBool:YES] forKey:@"hasSeenWelcomeMessage"];
	[prefs writeToFile:@"/var/mobile/Library/Preferences/com.subdiox.slicespreferences.plist" atomically:YES];

	int rawVersion = CURRENT_SETTINGS_VERSION;
	CFNumberRef versionReference = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &rawVersion);
	CFPreferencesSetAppValue(VERSION_KEY, versionReference, PREFERENCE_IDENTIFIER);
	

	if (!hasSeenWelcomeMessage) {
		UIAlertController *alert = [UIAlertController
                alertControllerWithTitle:Localize(@"Thank You")
                                 message:Localize(@"Thank you for purchasing Slices! By default, no applications are configured to use Slices. To enable some, visit the Settings.")
                          preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction: [UIAlertAction
                        actionWithTitle:Localize(@"OK")
                                  style:UIAlertActionStyleCancel
                                handler:nil]];
		[((UIViewController *)[%c(UIViewController) sharedInstance]) presentViewController:alert animated:YES completion:nil];

		hasSeenWelcomeMessage = YES;
		CFPreferencesSetAppValue(CFSTR("hasSeenWelcomeMessage"), kCFBooleanTrue, CFSTR("com.subdiox.slicespreferences"));
	}
}
%end

%hook SBIconView
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!isEnabled) {
		%orig;
	} else {
		//[self cancelLongPressTimer];

		BOOL touchDownInIcon = (BOOL)(MSHookIvar<unsigned int>(self, "_touchDownInIcon") & 0xFF);
		BOOL isGrabbed = (BOOL)(MSHookIvar<unsigned int>(self, "_isGrabbed") & 8);

		BOOL isEditing;
		if ([self respondsToSelector:@selector(setIsJittering:)]) {
			isEditing = (BOOL)(MSHookIvar<unsigned int>(self, "_isJittering") & 2);
		} else {
			isEditing = (BOOL)(MSHookIvar<unsigned int>(self, "_isEditing") & 2);
		}

		id<SBIconViewDelegate> delegate = MSHookIvar< id<SBIconViewDelegate> >(self, "_delegate");
		BOOL respondsToIconTapped = [delegate respondsToSelector:@selector(iconTapped:)];
		//BOOL allowsTapWhileEditing = [self allowsTapWhileEditing];

		SBApplication *application = [self application];
		BOOL isUserApplication = NO;

		if ([application respondsToSelector:@selector(dataContainerPath)]) {
			isUserApplication = [[application dataContainerPath] hasPrefix:@"/private/var/mobile/Containers/Data/Application/"];
		} else {
			isUserApplication = [[application info].dataContainerURL.path hasPrefix:@"/private/var/mobile/Containers/Data/Application/"];
		}

		BOOL wouldHaveLaunched = !isGrabbed && [self _delegateTapAllowed] && touchDownInIcon && !isEditing && respondsToIconTapped;
		if (wouldHaveLaunched && isUserApplication) {
			Slicer *slicer = [[Slicer alloc] initWithApplication:[self application] controller:[%c(SBApplicationController) sharedInstance]];
			NSLog(@"Slices: slicer=%@", slicer);
			BOOL askOnTouch = slicer.askOnTouch;

			if (askOnTouch) {
				NSString *actionSheetTitle;
				NSString *currentSlice = slicer.currentSlice;
				if (currentSlice.length > 0)
					actionSheetTitle = [NSString stringWithFormat:@"%@: %@", Localize(@"Current Slice"), currentSlice];
				else if (slicer.slices.count < 1)
					actionSheetTitle = Localize(@"All existing data will be copied into the new slice.");

				UIAlertController *alert = [UIAlertController
                alertControllerWithTitle:actionSheetTitle
                                 message:nil
                          preferredStyle:UIAlertControllerStyleActionSheet];
				// add button foreach slice
				NSArray *slices = slicer.slices;
				for (NSString *slice in slices) {
					[alert addAction:[UIAlertAction
								actionWithTitle:slice
													style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
						// switch slice
						Slicer *slicer = [[Slicer alloc] initWithApplication:[self application] controller:[%c(SBApplicationController) sharedInstance]];
						[slicer switchToSlice:action.title completionHandler:^(BOOL success) {
							// emulate the tap (launch the app)
							id<SBIconViewDelegate> delegate = MSHookIvar< id<SBIconViewDelegate> >(self, "_delegate");
							[delegate iconTapped:self];
	    			}];
					}]];
				}
				if (showNewSliceOption) {
					[alert addAction:[UIAlertAction
								actionWithTitle:Localize(@"New Slice")
													style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
						// ask for the slice name
						UIAlertController *alert = [UIAlertController
												alertControllerWithTitle:Localize(@"New Slice")
																				message:Localize(@"Enter the slice name")
																	preferredStyle:UIAlertControllerStyleAlert];
						[alert addAction: [UIAlertAction
																actionWithTitle:Localize(@"Cancel")
																					style:UIAlertActionStyleCancel
																				handler:nil]];
						[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
							textField.placeholder = @"slice name";
						}];
						[alert addAction:[UIAlertAction actionWithTitle:Localize(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
							NSString *sliceName = alert.textFields[0].text;
							
							// create the slice
							Slicer *slicer = [[Slicer alloc] initWithApplication:[self application] controller:[%c(SBApplicationController) sharedInstance]];
							BOOL created = [slicer createSlice:sliceName];

							// if no errors occured, emulate the tap
							if (created) {
								id<SBIconViewDelegate> delegate = MSHookIvar< id<SBIconViewDelegate> >(self, "_delegate");
								[delegate iconTapped:self];
							}
						}]];
						[[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
					}]];
				}
				[alert addAction: [UIAlertAction
														actionWithTitle:Localize(@"Cancel")
																			style:UIAlertActionStyleCancel
																		handler:nil]];
				[[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
			} else {
				[slicer switchToSlice:slicer.defaultSlice completionHandler:^(BOOL success) {
					%orig;
				}];
			}
		} else {
			%orig;
		}
	}
}

%new
- (SBApplication *)application {
	return [self.icon application];
}

%end

static void loadSettings() {
	CFPreferencesAppSynchronize(PREFERENCE_IDENTIFIER);
	
	Boolean keyExists;
	isEnabled = CFPreferencesGetAppBooleanValue(ENABLED_KEY, PREFERENCE_IDENTIFIER, &keyExists);
	isEnabled = (isEnabled || !keyExists);

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