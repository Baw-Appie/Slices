#import <Preferences/PSSpecifier.h>
// #import <Preferences/PSEditableListController.h>
// #import <Preferences/PSTextFieldSpecifier.h>
#import <Preferences/PSEditableTableCell.h>

#import "SlicesEditableTableCell.h"

#import "../Model/GameCenterAccountManager.h"
#import "../Headers/LocalizationKeys.h"

extern NSString* const PSDeletionActionKey;
extern NSString* const PSKeyNameKey;
extern NSString* const PSCellClassKey;
extern NSString* const PSEnabledKey;

@interface PSEditableTableCell (Private)
@property (nonatomic,strong) UITextField *textField;
@end

#define ADD_ACCOUNT_SPECIFIER_IDENTIFIER @"addAccount"

@interface PSEditableListController : PSListController
-(void)editDoneTapped;
-(id)_editButtonBarItem;
-(void)_setEditable:(BOOL)arg1 animated:(BOOL)arg2 ;
-(BOOL)performDeletionActionForSpecifier:(id)arg1 ;
-(void)setEditingButtonHidden:(BOOL)arg1 animated:(BOOL)arg2 ;
-(void)setEditButtonEnabled:(BOOL)arg1 ;
-(void)didLock;
-(void)showController:(id)arg1 animate:(BOOL)arg2 ;
-(void)_updateNavigationBar;
-(id)init;
-(void)viewWillAppear:(BOOL)arg1 ;
-(id)tableView:(id)arg1 willSelectRowAtIndexPath:(id)arg2 ;
-(long long)tableView:(id)arg1 editingStyleForRowAtIndexPath:(id)arg2 ;
-(void)tableView:(id)arg1 commitEditingStyle:(long long)arg2 forRowAtIndexPath:(id)arg3 ;
-(void)setEditable:(BOOL)arg1 ;
-(void)suspend;
-(BOOL)editable;
@end

@interface PSTextFieldSpecifier : PSSpecifier
+(id)specifierWithSpecifier:(id)arg1 ;
+(id)preferenceSpecifierNamed:(id)arg1 target:(id)arg2 set:(SEL)arg3 get:(SEL)arg4 detail:(Class)arg5 cell:(long long)arg6 edit:(Class)arg7 ;
-(void)setPlaceholder:(id)arg1 ;
-(id)placeholder;
-(BOOL)isEqualToSpecifier:(id)arg1 ;
@end

@interface GameCenterController : PSEditableListController
@end
