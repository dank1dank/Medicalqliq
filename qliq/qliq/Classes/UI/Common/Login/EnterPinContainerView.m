//
//  EnterPinContainerView.m
//  qliq
//
//  Created by Valerii Lider on 7/22/14.
//
//

#import "EnterPinContainerView.h"

#import "ChatMessage.h"

#import "QliqGroup.h"
#import <AudioToolbox/AudioToolbox.h>
#import "QliqPinButton.h"
#define kValueKeyboardViewCenterY -80.f

#define kTagRemoveButton 10

@interface EnterPinContainerView ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@property (weak, nonatomic) IBOutlet UIView *navigationUserView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (weak, nonatomic) IBOutlet UIButton *pin1;
@property (weak, nonatomic) IBOutlet UIButton *pin2;
@property (weak, nonatomic) IBOutlet UIButton *pin3;
@property (weak, nonatomic) IBOutlet UIButton *pin4;

//NSLayoutConstraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navigationUserViewLeading;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardViewCenterYConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loginQliqLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loginQliqWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *typeLabelLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *switchUserButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *switchUserButtonTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *switchUserLeadingConstraint;



@end

@implementation EnterPinContainerView

- (void)dealloc
{
    self.enterPinLabel = nil;
    self.switchUserButton = nil;
    
    self.avatarImageView = nil;
    self.nameLabel = nil;
    self.emailLabel = nil;
    
    self.pin1 = nil;
    self.pin2 = nil;
    self.pin3 = nil;
    self.pin4 = nil;
    
    self.badgeLabel = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)configureDefaultText {

    [self.switchUserButton setTitle:QliqLocalizedString(@"65-ButtonSwitchUser") forState:UIControlStateNormal];

    self.enterPinLabel.text = QliqLocalizedString(@"2313-TitleEnterYourPIN");
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view layoutIfNeeded];
    
    [self configureDefaultText];
    [self configureController];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    self.keyboardViewCenterYConstraint.constant = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? -10.f : kValueKeyboardViewCenterY;
}

#pragma mark - Private -

- (void)configureController
{
    self.pin = @"";
    
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2.f;
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.backgroundColor = [UIColor redColor];
    self.badgeLabel.layer.cornerRadius = 7.f;
    self.badgeLabel.clipsToBounds = YES;
}

- (void)updateTypeLableSize {
    
    //TypeLable
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [UIFont fontWithName:@"HelveticaNeue" size:19.0f], NSFontAttributeName,
                                          nil];
    
    CGRect typeLableRect = [self.typeLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, self.typeLableHeightConstraint.constant)
                                                             options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                          attributes:attributesDictionary
                                                             context:nil];
    
    self.typeLabelWidthConstraint.constant = typeLableRect.size.width + 1;
    
    //Calculating Total Free Space For Badge Label
    self.totalFreeSpaceForBadgeLabel =
    self.navigationUserView.frame.size.width -
    self.navigationUserViewLeading.constant -
    self.loginQliqLeadingConstraint.constant -
    self.loginQliqWidthConstraint.constant -
    self.typeLabelLeadingConstraint.constant -
    self.typeLabelWidthConstraint.constant;

}

- (void)updatePoints
{
    // As it is leaking about 25 bytes per call.
//    UIImage *checkedImage = [UIImage imageNamed:@"PinItemBlueChecked"];
//    UIImage *unCheckedImage = [UIImage imageNamed:@"PinItemBlue"];

    //Animation for delete button
    /*
    if ((self.deleteButton.hidden && self.pin.length > 0) ||
        (!self.deleteButton.hidden && self.pin.length == 0) ) {
        
        [UIView transitionWithView:self.deleteButton
                          duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:NULL
                        completion:NULL];
    }
     */
    self.deleteButton.hidden = self.pin.length == 0;

    [self.pin1 setImage:[UIImage imageNamed: (self.pin.length > 0) ? @"PinItemBlueChecked": @"PinItemBlue"]  forState:UIControlStateNormal];
    [self.pin2 setImage:[UIImage imageNamed: (self.pin.length > 1) ? @"PinItemBlueChecked": @"PinItemBlue"]  forState:UIControlStateNormal];
    [self.pin3 setImage:[UIImage imageNamed: (self.pin.length > 2) ? @"PinItemBlueChecked": @"PinItemBlue"]  forState:UIControlStateNormal];
    [self.pin4 setImage:[UIImage imageNamed: (self.pin.length > 3) ? @"PinItemBlueChecked": @"PinItemBlue"]  forState:UIControlStateNormal];

//    [self.pin1 setImage:(self.pin.length > 0) ? checkedImage : unCheckedImage forState:UIControlStateNormal];
//    [self.pin2 setImage:(self.pin.length > 1) ? checkedImage : unCheckedImage forState:UIControlStateNormal];
//    [self.pin3 setImage:(self.pin.length > 2) ? checkedImage : unCheckedImage forState:UIControlStateNormal];
//    [self.pin4 setImage:(self.pin.length > 3) ? checkedImage : unCheckedImage forState:UIControlStateNormal];

//    checkedImage = nil;
//    unCheckedImage = nil;
}

#pragma mark - Public - 

- (void)showHeaderWithContact:(QliqUser *)contact andGroup:(QliqGroup *)group
{
    self.nameLabel.text = contact.firstName;
    self.emailLabel.text = contact.email;
    
    self.avatarImageView.image = [[QliqAvatar sharedInstance] getAvatarForItem:contact withTitle:nil];
}

- (void)resetPinView
{
    self.pin = @"";
    [self updatePoints];
}

#pragma mark - Actions -

- (IBAction)onNumberButton:(UIButton *)button {
    
    UInt32 systemtSoundTock = 1104;
    AudioServicesPlaySystemSound(systemtSoundTock);
    
    if (button.tag == kTagRemoveButton) {
        if (self.pin.length > 0) {
            self.pin = [self.pin substringToIndex:self.pin.length - 1];
        }
    }
    else {
        if (self.pin.length < 4)
            self.pin = [self.pin stringByAppendingString:[NSString stringWithFormat:@"%ld",(long)button.tag]];
    }
    [self updatePoints];
    
    if (self.pin.length == 4) {
        [self.parentViewController performSelector:@selector(enterPin:) withObject:self.pin];
    }
}

@end
