#import <substrate.h>
#import <UIKit/UIKit.h>
#import <AppList/AppList.h>

#import "../Headers/LocalizationKeys.h"
#import "../Headers/SpringBoardHeaders.h"

#import "GameCenterAccountManager.h"

#import "RawSlicer.h"
#import "AppGroupSlicer.h"

#define SLICES_DIRECTORY @"/private/var/mobile/Library/Preferences/Slices/"

@interface SBIconView (New)
@property (readonly) SBApplication *application;

- (void)killApplication;
@end

@interface Slicer : RawSlicer
@property (readonly) NSString *displayIdentifier;
@property (nonatomic, strong) NSString *defaultSlice;
@property (nonatomic) BOOL askOnTouch;
@property (nonatomic) BOOL appSharing;

- (instancetype)initWithDisplayIdentifier:(NSString *)displayIdentifier;
- (instancetype)initWithApplication:(SBApplication *)application controller:(SBApplicationController *)applicationController;

- (NSString *)gameCenterAccountForSlice:(NSString *)sliceName;
- (void)setGameCenterAccount:(NSString *)gameCenterAccount forSlice:(NSString *)sliceName;

- (void)switchToSlice:(NSString *)targetSliceName completionHandler:(void (^)(BOOL))completionHandler;
- (BOOL)createSlice:(NSString *)sliceName;
- (BOOL)deleteSlice:(NSString *)sliceName;
@end
