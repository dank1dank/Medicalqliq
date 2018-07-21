//
//  SetNewPinContainerView.m
//  qliq
//
//  Created by Valerii Lider on 7/22/14.
//
//

#import "SetNewPinContainerView.h"
#import <AudioToolbox/AudioToolbox.h>

#define kValueKeyboardViewCenterY -90.f

@interface SetNewPinContainerView ()

@property (weak, nonatomic) IBOutlet UIButton *pin1;
@property (weak, nonatomic) IBOutlet UIButton *pin2;
@property (weak, nonatomic) IBOutlet UIButton *pin3;
@property (weak, nonatomic) IBOutlet UIButton *pin4;


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardViewCenterYConstraint;

@end

@implementation SetNewPinContainerView

- (void)dealloc
{
    self.enterPinLabel = nil;
    self.switchButton = nil;
    self.pin1 = nil;
    self.pin2 = nil;
    self.pin3 = nil;
    self.pin4 = nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.pin = @"";
    }
    return self;
}

- (void)configureDefaultText {
    self.enterPinLabel.text = QliqLocalizedString(@"2308-TitleSetupYourPIN");
    [self.switchButton setTitle:QliqLocalizedString(@"69-ButtonSwitchMmail/PasswordLogin") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    self.keyboardViewCenterYConstraint.constant = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? -15.f : kValueKeyboardViewCenterY;
}

#pragma mark - Private -

- (void)resetPinView
{
    self.pin = @"";
    [self updatePoints];
}

- (void)updatePoints
{
    [self.pin1 setImage:[UIImage imageNamed: (self.pin.length > 0) ? @"PinItemBlueChecked": @"PinItemBlue"]  forState:UIControlStateNormal];
    [self.pin2 setImage:[UIImage imageNamed: (self.pin.length > 1) ? @"PinItemBlueChecked": @"PinItemBlue"]  forState:UIControlStateNormal];
    [self.pin3 setImage:[UIImage imageNamed: (self.pin.length > 2) ? @"PinItemBlueChecked": @"PinItemBlue"]  forState:UIControlStateNormal];
    [self.pin4 setImage:[UIImage imageNamed: (self.pin.length > 3) ? @"PinItemBlueChecked": @"PinItemBlue"]  forState:UIControlStateNormal];
    /*
    UIImage *checkedImage = [UIImage imageNamed:@"PinItemBlueChecked"];
    UIImage *unCheckedImage = [UIImage imageNamed:@"PinItemBlue"];
    
    [self.pin1 setImage:(self.pin.length > 0) ? checkedImage : unCheckedImage forState:UIControlStateNormal];
    [self.pin2 setImage:(self.pin.length > 1) ? checkedImage : unCheckedImage forState:UIControlStateNormal];
    [self.pin3 setImage:(self.pin.length > 2) ? checkedImage : unCheckedImage forState:UIControlStateNormal];
    [self.pin4 setImage:(self.pin.length > 3) ? checkedImage : unCheckedImage forState:UIControlStateNormal];
    
    checkedImage = nil;
    unCheckedImage = nil;
     */
}

#pragma mark - Actions -

- (IBAction)onNumberButton:(UIButton*)button
{
    UInt32 systemtSoundTock = 1104;
    AudioServicesPlaySystemSound(systemtSoundTock);
    
    if (button.tag == 10) {
        if (self.pin.length > 0) {
            self.pin = [self.pin substringToIndex:self.pin.length - 1];
        }
    }
    else {
        if (self.pin.length < 4)
            self.pin = [self.pin stringByAppendingString:[NSString stringWithFormat:@"%ld",(long)button.tag]];
    }
    
    [self updatePoints];
    
    if (self.pin.length == 4)
        [self.parentViewController performSelector:@selector(enterPin:) withObject:self.pin];
}

@end
