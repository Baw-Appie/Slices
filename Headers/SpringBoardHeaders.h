#import <UIKit/UIKit.h>

@protocol SBIconViewDelegate <NSObject>
@optional
- (void)iconTapped:(id)arg1;
@end

@interface FBApplicationProcess : NSObject
- (void)stop;
@end

@interface LSApplicationProxy
+ (id)applicationProxyForIdentifier:(id)identifier;
- (id)_initWithBundleUnit:(NSUInteger)arg1 applicationIdentifier:(NSString *)arg2;
+ (id)applicationProxyForBundleURL:(NSURL *)arg1;
- (NSDictionary *)groupContainers;
@end

@interface SBApplicationInfo: NSObject
- (NSURL *)dataContainerURL;
@end

@interface SBApplication : NSObject
{
	FBApplicationProcess* _process;
}

@property (readonly) int pid;
@property NSString *displayIdentifier;
@property (nonatomic,readonly) SBApplicationInfo * info;

-(id)dataContainerPath;
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)applicationWithBundleIdentifier:(id)arg1;
@end

@interface SBIcon : NSObject
- (SBApplication *)application;
@end

@interface SBIconView : NSObject <UIActionSheetDelegate>
{
	BOOL _isGrabbed;
	BOOL _touchDownInIcon;
	BOOL _isEditing;
	id<SBIconViewDelegate> _delegate;
}
@property SBIcon *icon; 

- (void)_delegateTouchEnded:(BOOL)ended;
- (BOOL)_delegateTapAllowed;
- (void)setHighlighted:(BOOL)highlighted;
- (void)cancelLongPressTimer;
- (BOOL)allowsTapWhileEditing;
@end

@interface SBAppWindow : UIWindow
- (void)_updateInterfaceOrientationFromDeviceOrientation;
@end

@interface SBUIController
@property SBAppWindow *window;

- (SBUIController *)sharedInstance;
@end

@interface FBApplicationInfo
@property (nonatomic,retain,readonly) NSURL * dataContainerURL;
@end