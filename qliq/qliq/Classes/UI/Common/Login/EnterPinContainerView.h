//
//  EnterPinContainerView.h
//  qliq
//
//  Created by Valerii Lider on 7/22/14.
//
//

#import <UIKit/UIKit.h>

@class QliqGroup;

@interface EnterPinContainerView : UIViewController

@property (nonatomic, strong) NSString *pin;
@property (nonatomic, assign) CGFloat totalFreeSpaceForBadgeLabel;

@property (weak, nonatomic) IBOutlet UILabel *typeLabel;

@property (weak, nonatomic) IBOutlet UILabel *enterPinLabel;

@property (weak, nonatomic) IBOutlet UIButton *switchUserButton;

@property (weak, nonatomic) IBOutlet UILabel *badgeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeLabelWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *badgeLabelLeadingConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *typeLabelWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *typeLableHeightConstraint;

- (void)showHeaderWithContact:(QliqUser *)contact andGroup:(QliqGroup *)group;
- (void)resetPinView;
- (void)updateTypeLableSize;

@end
