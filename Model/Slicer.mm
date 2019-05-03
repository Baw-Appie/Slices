#import "Slicer.h"
#import "../Headers/SpringBoardHeaders.h"

@interface Slicer ()
@property (readwrite) NSString *displayIdentifier;

@property (assign) BOOL ignoreNextKill;

@property SBApplicationController *applicationController;
@property SBApplication *application;
@end

extern "C" void BKSTerminateApplicationForReasonAndReportWithDescription(NSString *app, int a, int b, NSString *description);

@implementation Slicer
- (instancetype)initWithApplication:(SBApplication *)application controller:(SBApplicationController *)applicationController {
	self = [super init];

	self.application = application;
	self.applicationController = applicationController;
	self.displayIdentifier = application.displayIdentifier;

	// get application directory
	if ([application respondsToSelector:@selector(dataContainerPath)]) {
		self.workingDirectory = [application dataContainerPath];
	} else {
		self.workingDirectory = [application info].dataContainerURL.path;
	}

	if (!self.workingDirectory)
		return nil;

	// get slices directory
	self.slicesDirectory = [SLICES_DIRECTORY stringByAppendingPathComponent:self.displayIdentifier];

	return self;
}

- (instancetype)initWithDisplayIdentifier:(NSString *)displayIdentifier {
  self = [super init];
  self.application = nil;
  self.displayIdentifier = displayIdentifier;

  // get application directory
  ALApplicationList *applicationList = [ALApplicationList sharedApplicationList];
  self.workingDirectory = [applicationList valueForKey:@"dataContainerPath" forDisplayIdentifier:displayIdentifier];
	
	if (!self.workingDirectory) {
		FBApplicationInfo *appInfo = [objc_getClass("LSApplicationProxy") applicationProxyForIdentifier: displayIdentifier];
		self.workingDirectory = appInfo.dataContainerURL.path;
	}

  if (!self.workingDirectory) {
		NSLog(@"[Slices] Error: working directory cannot be found");
    return nil;
	}

  // get slices directory
  self.slicesDirectory = [SLICES_DIRECTORY stringByAppendingPathComponent:displayIdentifier];
  return self;
}

- (NSArray *)appGroupSlicers {
	if (!self.appSharing)
		return @[ ];

	Class LSApplicationProxyClass = objc_getClass("LSApplicationProxy");
	if (LSApplicationProxyClass && [LSApplicationProxyClass instancesRespondToSelector:@selector(groupContainers)]) {
		NSString *mainSliceDirectory = [self.slicesDirectory stringByDeletingLastPathComponent];
		NSDictionary *appGroupContainers = [[LSApplicationProxyClass applicationProxyForIdentifier:self.displayIdentifier] groupContainers];

		NSMutableArray *appGroupSlicers = [[NSMutableArray alloc] init];
		for (NSString *groupIdentifier in [appGroupContainers allKeys]) {
			NSString *groupContainer = [appGroupContainers objectForKey:groupIdentifier];
			NSString *groupSlicesDirectory = [mainSliceDirectory stringByAppendingPathComponent:groupIdentifier];

			AppGroupSlicer *appGroupSlicer = [[AppGroupSlicer alloc] initWithWorkingDirectory:groupContainer slicesDirectory:groupSlicesDirectory];
			[appGroupSlicers addObject:appGroupSlicer];
		}
		
		return appGroupSlicers;
	} else {
		return @[ ];
	}
}

- (NSString *)defaultSlice {
	SliceSetting *defaultSliceSetting = [[SliceSetting alloc] initWithPrefix:@"def_"];
	return [defaultSliceSetting getValueInDirectory:self.slicesDirectory];
}

- (void)setDefaultSlice:(NSString *)defaultSlice {
	SliceSetting *defaultSliceSetting = [[SliceSetting alloc] initWithPrefix:@"def_"];
	[defaultSliceSetting setValueInDirectory:self.slicesDirectory value:defaultSlice];
}

- (NSString *)gameCenterAccountForSlice:(NSString *)sliceName {
	// yes, slice's slice directory (the slice directory that Slices uses to store the slice)
	NSString *slicesSliceDirectory = [self.slicesDirectory stringByAppendingPathComponent:sliceName];

	SliceSetting *gameCenterAccountSetting = [[SliceSetting alloc] initWithPrefix:@"gc_"];
	return [gameCenterAccountSetting getValueInDirectory:slicesSliceDirectory];
}

- (void)setGameCenterAccount:(NSString *)gameCenterAccount forSlice:(NSString *)sliceName {
	// yes, slice's slice directory (the slice directory that Slices uses to store the slice)
	NSString *slicesSliceDirectory = [self.slicesDirectory stringByAppendingPathComponent:sliceName];

	SliceSetting *gameCenterAccountSetting = [[SliceSetting alloc] initWithPrefix:@"gc_"];
	[gameCenterAccountSetting setValueInDirectory:slicesSliceDirectory value:gameCenterAccount];
}

- (void)setAskOnTouch:(BOOL)askOnTouch {
	SliceSetting *askOnTouchSliceSetting = [[SliceSetting alloc] initWithPrefix:@"e"];

	NSString *stringValue = (askOnTouch) ? @"1" : @"0";
	[askOnTouchSliceSetting setValueInDirectory:self.slicesDirectory value:stringValue];
}

- (BOOL)askOnTouch {
	SliceSetting *askOnTouchSliceSetting = [[SliceSetting alloc] initWithPrefix:@"e"];
	return [[askOnTouchSliceSetting getValueInDirectory:self.slicesDirectory] isEqualToString:@"1"];
}

- (void)setAppSharing:(BOOL)appSharing {
	SliceSetting *appSharingSliceSetting = [[SliceSetting alloc] initWithPrefix:@"s_"];

	NSString *stringValue = (appSharing) ? @"1" : @"0";
	[appSharingSliceSetting setValueInDirectory:self.slicesDirectory value:stringValue];
}

- (BOOL)appSharing {
	SliceSetting *appSharingSliceSetting = [[SliceSetting alloc] initWithPrefix:@"s_"];

	NSString *stringValue = [appSharingSliceSetting getValueInDirectory:self.slicesDirectory];
	return stringValue == nil || [stringValue isEqualToString:@"1"];
}

- (void)killApplication {
	if (self.ignoreNextKill) {
		self.ignoreNextKill = NO;
		return;
	}

	// if FBApplicationProcess has 'stop', use that
	Class FBApplicationProcessClass = objc_getClass("FBApplicationProcess");
	if ([FBApplicationProcessClass instancesRespondToSelector:@selector(stop)]) {
		if (self.application) {
			FBApplicationProcess *process = MSHookIvar<FBApplicationProcess *>(self.application, "_process");
			[process stop];
		}
	} else {
		BKSTerminateApplicationForReasonAndReportWithDescription(self.displayIdentifier, 5, NO, @"Killed from Slices");
	}

	// must kill this in iOS 8
	pid_t pid;
  const char *args[] = {"sh", "-c", "sud0 launchctl stop com.apple.cfprefsd.xpc.daemon", NULL};
  posix_spawn(&pid, "/bin/sh", NULL, NULL, (char* const*)args, NULL);

	[NSThread sleepForTimeInterval:0.1];
}

- (void)switchToSlice:(NSString *)targetSliceName completionHandler:(void (^)(BOOL))completionHandler {
	if (targetSliceName.length > 0 && ![self.currentSlice isEqualToString:targetSliceName]) {
		[self killApplication];
	}

	NSArray *IGNORE_SUFFIXES = @[ @".app", @"iTunesMetadata.plist", @"iTunesArtwork", @"Slices", @".com.apple.mobile_container_manager.metadata.plist"];
	BOOL success = [super switchToSlice:targetSliceName ignoreSuffixes:IGNORE_SUFFIXES];
	if (!success) {
		if (completionHandler)
			completionHandler(NO);
		return;
	}

	NSArray *appGroupSlicers = [self appGroupSlicers];
	for (AppGroupSlicer *appGroupSlicer in appGroupSlicers) {
		if (![appGroupSlicer switchToSlice:targetSliceName]) {
			success = NO;
		}
	}

	NSString *gameCenterAccount = [self gameCenterAccountForSlice:targetSliceName];
	GameCenterAccountManager *gameCenterAccountManager = [GameCenterAccountManager sharedInstance];
	[gameCenterAccountManager switchToAccount:gameCenterAccount completionHandler:^(BOOL gameCenterSuccess) {
		if (completionHandler) {
			completionHandler(success && gameCenterSuccess);
		}
	}];
}

- (BOOL)createSlice:(NSString *)newSliceName {
	if (self.currentSlice.length > 0) {
		[self killApplication];
	}

	NSArray *IGNORE_SUFFIXES = @[ @".app", @"iTunesMetadata.plist", @"iTunesArtwork", @"Slices", @".com.apple.mobile_container_manager.metadata.plist" ];
	BOOL success = [super createSlice:newSliceName ignoreSuffixes:IGNORE_SUFFIXES];
	if (!success) {
		return NO;
	}

	NSFileManager *manager = [NSFileManager defaultManager];
	NSArray *DIRECTORIES = @[ @"tmp", @"Documents", @"StoreKit", @"Library" ];
	for (NSString *directory in DIRECTORIES) {
		NSString *currentDirectoryFullPath = [self.workingDirectory stringByAppendingPathComponent:directory];
		if (![manager createDirectoryAtPath:currentDirectoryFullPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
			success = NO;
		}
	}

	NSArray *appGroupSlicers = [self appGroupSlicers];
	for (AppGroupSlicer *appGroupSlicer in appGroupSlicers) {
		if (![appGroupSlicer createSlice:newSliceName]) {
			success = NO;
		}
	}

	// update default slice
	if (self.defaultSlice.length < 1) {
		self.defaultSlice = newSliceName;
	}

	return success;
}

- (BOOL)deleteSlice:(NSString *)sliceName {
	if ([sliceName isEqualToString:self.currentSlice])
		[self killApplication];

	NSArray *IGNORE_SUFFIXES = @[ @".app", @"iTunesMetadata.plist", @"iTunesArtwork", @"Slices", @".com.apple.mobile_container_manager.metadata.plist" ];
	BOOL success = [super deleteSlice:sliceName ignoreSuffixes:IGNORE_SUFFIXES];
	if (!success) {
		return NO;
	}

	NSArray *appGroupSlicers = [self appGroupSlicers];
	for (AppGroupSlicer *appGroupSlicer in appGroupSlicers) {
		if (![appGroupSlicer deleteSlice:sliceName]) {
			success = NO;
		}
	}

	NSArray *slices = self.slices;
	NSString *defaultSlice = self.defaultSlice;
	
	// update default slice
	if ([defaultSlice isEqualToString:sliceName]) {
		if (slices.count > 0) {
			self.defaultSlice = slices[0];
			defaultSlice = slices[0];
		} else {
			self.defaultSlice = nil;
			defaultSlice = nil;
		}
	}

	// update current slice
	if ([self.currentSlice isEqualToString:sliceName]) {
		self.currentSlice = nil;
		self.ignoreNextKill = YES;

		if (defaultSlice.length > 0) {
			[self switchToSlice:defaultSlice completionHandler:nil];
		} else {
			[self switchToSlice:slices[0] completionHandler:nil];
		}
	}

	self.ignoreNextKill = NO;
	return success;
}

- (BOOL)renameSlice:(NSString *)originaSliceName toName:(NSString *)targetSliceName {
	BOOL success = [super renameSlice:originaSliceName toName:targetSliceName];
	if (!success) {
		return NO;
	}

	NSArray *appGroupSlicers = [self appGroupSlicers];
	for (AppGroupSlicer *appGroupSlicer in appGroupSlicers) {
		if (![appGroupSlicer renameSlice:originaSliceName toName:targetSliceName]) {
			success = NO;
		}
	}

	if ([self.defaultSlice isEqualToString:originaSliceName]) {
		self.defaultSlice = targetSliceName;
	}

	return success;
}

@end
