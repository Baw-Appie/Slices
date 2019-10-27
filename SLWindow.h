#import <UIKit/UIKit.h>

@interface SLWindow : UIWindow
@property (nonatomic) BOOL touchInjection;
+ (instancetype)sharedInstance;
- (id)init;
@end
