//
//  EnterPassContainerView.h
//  qliq
//
//  Created by Valerii Lider on 7/23/14.
//
//

#import <UIKit/UIKit.h>

@class QliqGroup;

@protocol EnterPassContainerViewDelegate <NSObject>

@optional

@end

@interface EnterPassContainerView : UIViewController

@property (nonatomic, weak) id<EnterPassContainerViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (nonatomic, assign) CGFloat totalFreeSpaceForBadgeLabel;

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passTextField;

@property (weak, nonatomic) IBOutlet UIButton *switchUserButton;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

@property (weak, nonatomic) IBOutlet UIView *backButtonView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *typeLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *typeLabelWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeLabelLeadingConstraint;
@property (weak, nonatomic) IBOutlet UILabel *badgeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeLabelWidthConstraint;

- (void)configureHeaderWithUser:(QliqUser *)contact andGroup:(QliqGroup *)group;
- (void)updateTypeLableSize;
@end
