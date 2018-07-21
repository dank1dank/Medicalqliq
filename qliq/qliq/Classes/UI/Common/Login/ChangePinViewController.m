//
//  ChangePinViewController.m
//  qliq
//
//  Created by Valerii Lider on 05/10/15.
//
//

#import "ChangePinViewController.h"

#import "SetNewPinContainerView.h"

#import <AudioToolbox/AudioServices.h>

#import "NSString+Base64.h"
#import "KeychainService.h"
#import "AlertController.h"

typedef NS_ENUM (NSInteger, ChangePinAction) {
    ActionEnterCurrentPIN,
    ActionEnterNewPIN,
    ActionConfirmPIN
};

@interface ChangePinViewController ()

@property (weak, nonatomic) IBOutlet UIView *setNewPinContainerView;
@property (weak, nonatomic) SetNewPinContainerView *setNewPinVc;

@property (nonatomic, assign) ChangePinAction currentAction;

@property (strong, nonatomic) NSString *enteredPin;

@end

@implementation ChangePinViewController

- (void)dealloc
{
    self.setNewPinVc = nil;
    self.setNewPinContainerView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureChildViewControllers];
    self.currentAction = [[KeychainService sharedService] pinAvailable] ? ActionEnterCurrentPIN : ActionEnterNewPIN;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

- (void)configureChildViewControllers
{
    for (UIViewController *controller in self.childViewControllers)
    {
        if ([controller isKindOfClass:[SetNewPinContainerView class]]) {
            self.setNewPinVc = (SetNewPinContainerView *)controller;
            self.setNewPinVc.qliqLogoImageView.hidden = YES;
            [self.setNewPinVc.backButton addTarget:self action:@selector(onBack:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)didEnterWrongPin
{
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    [self resetPinView];
}

- (void)resetPinView
{
    [self.setNewPinVc resetPinView];
}

- (void)enterPin:(NSString *)pin
{
    switch (self.currentAction)
    {
        case ActionEnterCurrentPIN: {
            
            if ([self checkCurrentPin:pin]) {
                self.currentAction = ActionEnterNewPIN;
            }
            else {
                self.currentAction = ActionEnterCurrentPIN;
            }
            
            break;
        }
        case ActionEnterNewPIN: {
            
            self.enteredPin = pin;
            
            self.currentAction = ActionConfirmPIN;
            
            break;
        }
        case ActionConfirmPIN:{
            
            if ([self confirmWithPin:pin]){
                [[KeychainService sharedService] savePin:pin];
                [self onBack:nil];
            }
            else {
                self.currentAction = ActionEnterNewPIN;
            }
            
            break;
        }
        default:
            break;
    }
}

- (BOOL)checkCurrentPin:(NSString *)pin {
    
    NSString *encodedPin = [pin base64EncodedString];
    NSString *currentPin = [[KeychainService sharedService] getPin];
    
    BOOL correctPin = [currentPin isEqualToString:encodedPin];
    
    if (!correctPin){
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"1026-TextIncorrectPIN")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
    }
    return correctPin;
}

- (BOOL)confirmWithPin:(NSString *)pin {
    
    BOOL correctPin = [self.enteredPin isEqualToString:pin];
    if (!correctPin) {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"1027-TextMismatchPIN")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
    }
    return correctPin;
    
}

#pragma mark - Setters

- (void)setCurrentAction:(ChangePinAction)currentAction
{
    _currentAction = currentAction;
    
    [self resetPinView];
    
    switch (currentAction) {
            
        case ActionEnterCurrentPIN: {

            self.setNewPinVc.enterPinLabel.text = QliqLocalizedString(@"2314-TitleEnterYourCurrentPIN");
            break;
        }
        case ActionEnterNewPIN: {
            
            self.setNewPinVc.enterPinLabel.text = QliqLocalizedString(@"2315-TitleCreateYourNewPIN");
            break;
        }
        case ActionConfirmPIN: {
            
            self.setNewPinVc.enterPinLabel.text = QliqLocalizedString(@"2316-TitleConfirmYourNewPIN");
            break;
        }
        default:
            break;
    }
}

#pragma mark - Actions

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
