//
//  PasswordChangeViewController.h
//  qliq
//
//  Created by Developer on 14.11.13.
//
//

#import "QliqBaseViewController.h"

@protocol PasswordChangeViewControllerDelegate <NSObject>

- (void)passwordChangeControllerNeedsRelogin;

@end

@interface PasswordChangeViewController : QliqBaseViewController

@property (nonatomic, weak) NSObject<PasswordChangeViewControllerDelegate> *delegate;
- (void)closeKeyboard;
- (void)reset;
- (void)focusOnPasswordField;
@end
