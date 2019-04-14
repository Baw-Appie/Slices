#import <UIKit/UIKit.h>

@interface UIApplication (Private)
- (void)_relaunchSpringBoardNow;
- (id)_accessibilityFrontMostApplication;
- (void)launchApplicationWithIdentifier: (NSString*)identifier suspended: (BOOL)suspended;
- (id)displayIdentifier;
- (void)setStatusBarHidden:(bool)arg1 animated:(bool)arg2;
void receivedStatusBarChange(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
void receivedLandscapeRotate();
void receivedPortraitRotate();
@end

@interface FBApplicationProcess : NSObject
- (void)stop;
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
@property(copy) NSString* bundleIdentifier;

-(id)dataContainerPath;
@end

@interface SBIcon : NSObject
- (SBApplication *)application;
- (id)applicationBundleID;
@end

@protocol SBIconViewDelegate <NSObject>
@optional
- (void)iconTapped:(id)arg1;
@end

@interface SBIconView : UIView
{
	BOOL _isGrabbed;
	BOOL _touchDownInIcon;
	BOOL _isEditing;
	id<SBIconViewDelegate> _delegate;
}
@property SBIcon *icon;
@property (nonatomic,retain) UIGestureRecognizer * editingGestureRecognizer;
@property (nonatomic,retain) UIGestureRecognizer * appIconForceTouchGestureRecognizer;
@property (nonatomic,assign) BOOL didPresentAfterPeek;

- (void)_handleSecondHalfLongPressTimer:(id)arg1;
// - (SBUIIconForceTouchViewController *)_iconForceTouchViewController;
- (void)_delegateTouchEnded:(BOOL)ended;
- (BOOL)_delegateTapAllowed;
- (void)setHighlighted:(BOOL)highlighted;
- (void)cancelLongPressTimer;
- (BOOL)allowsTapWhileEditing;
@end

@interface SBUIIconForceTouchIconViewWrapperView : NSObject
@property (nonatomic,readonly) SBIconView * iconView;
@end

@interface SBUIIconForceTouchViewController : UIViewController <UIGestureRecognizerDelegate> {
	SBUIIconForceTouchIconViewWrapperView* _iconViewWrapperViewBelow;
	SBUIIconForceTouchIconViewWrapperView* _iconViewWrapperViewAbove;
}
-(void)_presentAnimated:(BOOL)arg1 withCompletionHandler:(/*^block*/id)arg2 ;
-(void)_dismissAnimated:(BOOL)arg1 withCompletionHandler:(/*^block*/id)arg2 ;
@end

@interface SBUIIconForceTouchController : NSObject
@property (nonatomic,readonly) SBUIIconForceTouchViewController * iconForceTouchViewController;
- (void)_dismissAnimated:(BOOL)arg1 withCompletionHandler:(/*^block*/id)arg2 ;
- (void)dismissAnimated:(BOOL)arg1 withCompletionHandler:(/*^block*/id)arg2 ;
// - (void)_setupWithGestureRecognizer:(SBUIForceTouchGestureRecognizer *)recognizer;
- (void)_presentAnimated:(BOOL)animated withCompletionHandler:(id)handler;
@end

@interface SBUIAppIconForceTouchControllerDataProvider
@property (nonatomic,readonly) NSString * applicationBundleIdentifier;
@end

@interface LSApplicationProxy
+ (id)applicationProxyForIdentifier:(id)identifier;
- (id)_initWithBundleUnit:(NSUInteger)arg1 applicationIdentifier:(NSString *)arg2;
+ (id)applicationProxyForBundleURL:(NSURL *)arg1;
- (NSDictionary *)groupContainers;
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (id)applicationWithBundleIdentifier:(id)arg1;
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
