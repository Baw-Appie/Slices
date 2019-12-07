#import <substrate.h>

#import <UIKit/UIKit.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>
// #import <Preferences/PSTextFieldSpecifier.h>
#import <Preferences/PSListItemsController.h>

#import "SlicesEditableTableCell.h"

#import "../Model/Slicer.h"
#import "../Model/GameCenterAccountManager.h"
#import "../Headers/LocalizationKeys.h"

extern NSString* const PSKeyNameKey;
extern NSString* const PSIsRadioGroupKey;
extern NSString* const PSCellClassKey;
extern NSString* const PSRadioGroupCheckedSpecifierKey;
extern NSString* const PSActionKey;

@interface PSEditableTableCell (Private)
@property (nonatomic,strong) UITextField *textField;
@end

@interface PSTextFieldSpecifier : PSSpecifier
+(id)specifierWithSpecifier:(id)arg1 ;
+(id)preferenceSpecifierNamed:(id)arg1 target:(id)arg2 set:(SEL)arg3 get:(SEL)arg4 detail:(Class)arg5 cell:(long long)arg6 edit:(Class)arg7 ;
-(void)setPlaceholder:(id)arg1 ;
-(id)placeholder;
-(BOOL)isEqualToSpecifier:(id)arg1 ;
@end

#define NAME_SPECIFIER_IDENTIFIER @"name"

@interface SliceDetailController : PSListController
@end
