#import "SlicesAppDetailController.h"

extern NSString* const PSDeletionActionKey;

@interface UIPreferencesTable
- (void)reloadData;
@end

@interface SlicesAppDetailController () // PSEditableListController : PSListController
{
	Slicer *_slicer;
	PSSpecifier *_defaultSpecifier;
}

- (void)reloadSpecifiers;
@end

@implementation SlicesAppDetailController
- (id)specifiers
{
	if(_specifiers == nil)
		[self reloadSpecifiers];

	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[self refreshView:YES];
}

- (void)reloadSpecifiers {
	// create a slicer
	if (!_slicer) {
		NSString *displayIdentifier = self.specifier.properties[@"displayIdentifier"];
		_slicer = [[Slicer alloc] initWithDisplayIdentifier:displayIdentifier];
	}

	// create a temporary specifiers array (mutable)
	NSMutableArray *specifiers = [[NSMutableArray alloc] init];

	// general group specifier
	PSSpecifier *generalGroupSpecifier = [PSSpecifier preferenceSpecifierNamed:@"General" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
	[generalGroupSpecifier.properties setValue:@"If the Ask on Touch switch is enabled, you will be asked which slice to use when tapping the application's icon on the homescreen.\n\nIf it's disabled, the application will start with the specified Default Slice." forKey:@"footerText"];
	[specifiers addObject:generalGroupSpecifier];

	// app-specific switch specifier
	PSSpecifier *appSpecificSwitchSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Ask on Touch" target:self set:@selector(setAppSpecificAsk:forSpecifier:) get:@selector(getAppSpecificAsk:) detail:nil cell:PSSwitchCell edit:nil];
	[specifiers addObject:appSpecificSwitchSpecifier];

	// default list specifier
	_defaultSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Default Slice" target:self set:@selector(setDefaultSlice:forSpecifier:) get:@selector(getDefaultSlice:) detail:[PSListItemsController class] cell:PSLinkListCell edit:nil];
	[_defaultSpecifier.properties setValue:@"valuesSource:" forKey:@"valuesDataSource"];
	[_defaultSpecifier.properties setValue:@"valuesSource:" forKey:@"titlesDataSource"];
	[specifiers addObject:_defaultSpecifier];

	// slices group specifier
	PSSpecifier *slicesGroupSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Slices" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
	[slicesGroupSpecifier.properties setValue:@"Deleting a slice will delete all the data associated with it. To rename a slice, tap it. If no slices exists and you create one, all the existing data will be copied into the new slice." forKey:@"footerText"];
	[specifiers addObject:slicesGroupSpecifier];

	// create the specifiers
	NSArray *slices = _slicer.slices;
	for (NSString *slice in slices) {
		PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:slice target:self set:nil get:nil detail:[SliceDetailController class] cell:PSLinkListCell edit:nil];
		//specifier->action = @selector(renameSlice:);
		[specifier setProperty:NSStringFromSelector(@selector(removedSpecifier:)) forKey:PSDeletionActionKey];
		[specifier.properties setValue:_slicer forKey:@"slicer"];
		[specifier.properties setValue:@"1" forKey:@"neverLocalize"];
		[specifiers addObject:specifier];
	}

	// if there aren't any slices, tell them
	if (slices.count < 1) {
		[specifiers addObject:[PSSpecifier preferenceSpecifierNamed:@"No Slices" target:self set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil]];
		[self setEditingButtonHidden:YES animated:NO];
	} else {
		[self setEditingButtonHidden:NO animated:YES];
	}

	// create slice button specifier
	PSSpecifier *createSliceSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Create Slice" target:self set:nil get:nil detail:nil cell:PSButtonCell edit:nil];
	[createSliceSpecifier setButtonAction:@selector(createSlice:)];
	[specifiers addObject:createSliceSpecifier];

	// advanced group specifier
	PSSpecifier *advancedGroupSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Advanced" target:self set:nil get:nil detail:nil cell:PSGroupCell edit:nil];
	[advancedGroupSpecifier.properties setValue:@"Disabling will leave data shared with other applications untouched." forKey:@"footerText"];
	[specifiers addObject:advancedGroupSpecifier];

	// app-sharing switch specifier
	PSSpecifier *appSharingSwitchSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Include Shared Data" target:self set:@selector(setAppSharing:forSpecifier:) get:@selector(getAppSharing:) detail:nil cell:PSSwitchCell edit:nil];
	[specifiers addObject:appSharingSwitchSpecifier];

	// localize all the strings
	NSBundle *bundle = [NSBundle bundleWithPath:@"/Library/Application Support/Slices/Slices.bundle"];
	for (PSSpecifier *specifier in specifiers) {
		NSString *footerTextValue = [specifier propertyForKey:@"footerText"];
		if (footerTextValue) {
			[specifier setProperty:Localize(footerTextValue) forKey:@"footerText"];
		}

		NSString *name = specifier.name; // "label" key in plist
		if (name) {
			if (![[specifier propertyForKey:@"neverLocalize"] isEqual:@"1"]) {
				specifier.name = Localize(name);
			}
		}
	}

	// update the specifier ivar (immutable)
	_specifiers = [specifiers copy];
}

- (void)createSlice:(PSSpecifier *)specifier {
	UIAlertController *alert = [UIAlertController
							alertControllerWithTitle:Localize(@"New Slice")
															message:Localize(@"Enter the slice name")
												preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction: [UIAlertAction
											actionWithTitle:Localize(@"Cancel")
																style:UIAlertActionStyleCancel
															handler:nil]];
	[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
			textField.text = [NSString stringWithFormat:Localize(@"Slice %d"), _slicer.slices.count + 1];
	}];
	[alert addAction:[UIAlertAction actionWithTitle:Localize(@"Create Slice") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		// they want to create a slice

		// get the entered slice name
		NSString *sliceName = alert.textFields[0].text;

		// create the slice
		BOOL created = [_slicer createSlice:sliceName];

		// if no errors occurred, emulate the tap
		if (created) {
			NSLog(@"Slices: slice created!");
			// successfully created
			// maybe do stuff in the future here
		} else {
			NSLog(@"Slices: slice creation failed");
		}
		
		[self refreshView:YES];

		_specifierToRename = nil;
	}]];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)renameSlice:(PSSpecifier *)specifier
{
	_specifierToRename = specifier;

	UIAlertController *alert = [UIAlertController
							alertControllerWithTitle:Localize(@"Rename Slice")
															message:Localize(@"Enter the new slice name")
												preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction: [UIAlertAction
											actionWithTitle:Localize(@"Cancel")
																style:UIAlertActionStyleCancel
															handler:nil]];
	[alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
			textField.text = specifier.name;
	}];
	[alert addAction:[UIAlertAction actionWithTitle:Localize(@"Rename Slice") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		// they want to rename a slice
		NSString *originalSliceName = _specifierToRename.name;

		NSString *targetSliceName = alert.textFields[0].text;

		[_slicer renameSlice:originalSliceName toName:targetSliceName];
		[self refreshView:YES];

		_specifierToRename = nil;
	}]];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)setDefaultSlice:(NSString *)sliceName forSpecifier:(PSSpecifier*)specifier
{
	_slicer.defaultSlice = sliceName;
}

- (NSString *)getDefaultSlice:(PSSpecifier *)specifier
{
	NSString *defaultSlice = _slicer.defaultSlice;
	if (defaultSlice)
		return defaultSlice;

	return Localize(@"Default");
}

- (void)setAppSpecificAsk:(NSNumber *)askNumber forSpecifier:(PSSpecifier*)specifier
{
	_slicer.askOnTouch = [askNumber boolValue];
}

- (NSNumber *)getAppSpecificAsk:(PSSpecifier *)specifier
{
	return [NSNumber numberWithBool:_slicer.askOnTouch];
}

- (void)setAppSharing:(NSNumber *)shareNumber forSpecifier:(PSSpecifier*)specifier
{
	_slicer.appSharing = [shareNumber boolValue];
}

- (NSNumber *)getAppSharing:(PSSpecifier *)specifier
{
	return [NSNumber numberWithBool:_slicer.appSharing];
}

- (long long)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)canEditRowAtIndexPath
{
	int index = [self indexForIndexPath:canEditRowAtIndexPath];
	PSSpecifier *specifier = _specifiers[index];
	return specifier.detailControllerClass == [SliceDetailController class];
}

- (void)removedSpecifier:(PSSpecifier *)specifier
{
	[_slicer deleteSlice:specifier.name];
	[self refreshView:NO];
}

- (NSArray *)valuesSource:(id)target
{
	NSArray *slices = _slicer.slices;
	if (slices.count < 1)
		return @[ Localize(@"Default") ];
	return slices;
}

- (void)refreshView:(BOOL)forceHardReload
{
	[_defaultSpecifier loadValuesAndTitlesFromDataSource];

	if (forceHardReload || _slicer.slices.count < 1) {
		[self reloadSpecifiers];
	}

	[[self table] reloadData];
	[self reload];
}

- (BOOL)canBeShownFromSuspendedState
{
	return NO;
}
@end
