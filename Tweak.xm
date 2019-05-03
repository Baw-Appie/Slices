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

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
	%orig;

	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.subdiox.slicespreferences.plist"];
	if (!prefs) {
		prefs = [[NSMutableDictionary alloc] init];
	}

	[prefs writeToFile:@"/var/mobile/Library/Preferences/com.subdiox.slicespreferences.plist" atomically:YES];

	int rawVersion = CURRENT_SETTINGS_VERSION;
	CFNumberRef versionReference = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &rawVersion);
	CFPreferencesSetAppValue(VERSION_KEY, versionReference, PREFERENCE_IDENTIFIER);
}
%end

%hook SBIconView
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!isEnabled) {
		%orig;
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
			Slicer *slicer = [[Slicer alloc] initWithApplication:[self application] controller:[%c(SBApplicationController) sharedInstance]];
			BOOL askOnTouch = slicer.askOnTouch;

			if (askOnTouch) {
				NSString *actionSheetTitle;
				NSString *currentSlice = slicer.currentSlice;
				if (currentSlice.length > 0)
					actionSheetTitle = [NSString stringWithFormat:@"%@: %@", Localize(@"Current Slice"), currentSlice];
				else if (slicer.slices.count < 1)
					actionSheetTitle = Localize(@"All existing data will be copied into the new slice.");

				UIAlertController *alert = [UIAlertController alertControllerWithTitle:actionSheetTitle message:nil preferredStyle:UIAlertControllerStyleActionSheet];
				// add button foreach slice
				NSArray *slices = slicer.slices;
				for (NSString *slice in slices) {
					[alert addAction:[UIAlertAction actionWithTitle:slice style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
						// switch slice
						Slicer *slicer = [[Slicer alloc] initWithApplication:[self application] controller:[%c(SBApplicationController) sharedInstance]];
						[slicer switchToSlice:action.title completionHandler:^(BOOL success) {
							// emulate the tap (launch the app)
							[delegate iconTapped:self];
						}];
					}]];
				}
				if (showNewSliceOption) {
					[alert addAction:[UIAlertAction actionWithTitle:Localize(@"New Slice") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
						// ask for the slice name
						Slicer *slicer = [[Slicer alloc] initWithApplication:[self application] controller:[%c(SBApplicationController) sharedInstance]];
						
						UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localize(@"New Slice") message:Localize(@"Enter the slice name") preferredStyle:UIAlertControllerStyleAlert];
						[alert addAction: [UIAlertAction actionWithTitle:Localize(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
						}]];
						[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
							textField.text = [NSString stringWithFormat:Localize(@"Slice %d"), slicer.slices.count + 1];
							textField.placeholder = Localize(@"Slice Name");
						}];
						[alert addAction:[UIAlertAction actionWithTitle:Localize(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
							NSString *sliceName = alert.textFields[0].text;
							
							// create the slice
							BOOL created = [slicer createSlice:sliceName];

							// if no errors occured, emulate the tap
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