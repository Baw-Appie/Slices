#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

#import <Social/Social.h>

#import <AppList/AppList.h>

#import "../Headers/SpringBoardHeaders.h"
#import "../Model/GameCenterAccountManager.h"
#import "../Headers/LocalizationKeys.h"

@interface SlicesPreferencesListController : PSListController
@end

@implementation SlicesPreferencesListController
- (id)specifiers
{
	if(_specifiers == nil)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"SlicesPreferences" target:self];

		// localize all the strings
		// NSBundle *bundle = [NSBundle bundleWithPath:@"/Library/Application Support/Slices/Slices.bundle"];

		HBLogDebug(@"3D Touch %d", self.traitCollection.forceTouchCapability != UIForceTouchCapabilityAvailable);

		for (PSSpecifier *specifier in _specifiers)
		{
			NSString *footerTextValue = [specifier propertyForKey:@"footerText"];
			if (footerTextValue)
				[specifier setProperty:Localize(footerTextValue) forKey:@"footerText"];

			NSString *name = specifier.name; // "label" key in plist
			if (name) specifier.name = Localize(name);
			if([name isEqualToString:@"Use 3D touch instead of normal touch"] && self.traitCollection.forceTouchCapability != UIForceTouchCapabilityAvailable) [self removeSpecifier:specifier];
		}
	}

	return _specifiers;
}

- (void)openTwitter:(id)arg1
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/BawAppie"] options:@{} completionHandler:nil];
}
@end
