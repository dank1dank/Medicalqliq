//
//  SetupNewPinQuestionViewController.m
//  qliq
//
//  Created by Valerii Lider on 6/4/14.
//
//

#import "SetupNewPinQuestionViewController.h"
#import "UIDevice-Hardware.h"

#import "Login.h"
#import "LoginWithPinViewController.h"

@interface SetupNewPinQuestionViewController () <LoginDelegate>

@property (weak, nonatomic) IBOutlet UILabel *descriptionTitleLabel;

@property (weak, nonatomic) IBOutlet UILabel *description1Label;

@property (weak, nonatomic) IBOutlet UILabel *description2Label;

@property (weak, nonatomic) IBOutlet UIButton *setPinLaterButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

/*Constraint for iPhone X*/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewBottomConstraint;


@end

@implementation SetupNewPinQuestionViewController 

- (void)dealloc
{
    self.setPinLaterButton = nil;
    self.nextButton = nil;
}

- (void)configureDefaultText {
    
    self.descriptionTitleLabel.text = QliqLocalizedString(@"2310-TitleSetupPinLater");
    self.description1Label.text = QliqLocalizedString(@"2311-TitleSetupPinLaterDescription1");
    self.description2Label.text = QliqLocalizedString(@"2312-TitleSetupPinLaterDescription2");
    
    [self.setPinLaterButton setTitle:QliqLocalizedString(@"67-ButtonSetupLater") forState:UIControlStateNormal];
    [self.nextButton setTitle:QliqLocalizedString(@"68-ButtonNext") forState:UIControlStateNormal];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*Change constraint for iPhone X*/
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        isIPhoneX {
            weakSelf.backgroundViewBottomConstraint.constant = weakSelf.backgroundViewBottomConstraint.constant -35.0f;
            [weakSelf.view layoutIfNeeded];
        }
    });
    [self configureDefaultText];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:YES];
    
    [Login sharedService].delegate = self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)alertWithTitle:(NSString*)title message:(NSString*)message
{
   dispatch_async_main(^{
       UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:title
                                                                     message:message
                                                                    delegate:nil
                                                           cancelButtonTitle:NSLocalizedString(@"1-ButtonOK", nil)
                                                           otherButtonTitles: nil];
       [alert showWithDissmissBlock:NULL];
   });
}

#pragma mark - Actions -

- (IBAction)onSetPinLater:(id)sender {

    NSString *statusTitle = NSLocalizedString(@"1913-StatusLogin", @"Login");
    [SVProgressHUD showWithStatus:statusTitle maskType:SVProgressHUDMaskTypeBlack dismissButtonTitle:NSLocalizedString(@"4-ButtonCancel", @"Cancel")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[Login sharedService] setPinLater];
    });
 
}

- (IBAction)onNext:(id)sender
{
    LoginWithPinViewController *controller = [kDefaultStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([LoginWithPinViewController class])];
    controller.action = ActionTipePinSet;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Login Delegate

- (void)loginError:(NSError *)error title:(NSString *)title message:(NSString *)message {
    
    DDLogSupport(@"login request error: %@",error);
    dispatch_async_main(^{
        [SVProgressHUD dismiss];
    });
    [Login sharedService].isLoginRunning = NO;
    
    if((title.length || message.length) && !error.code)
    {
        [self alertWithTitle:title message:message];
        return;
    }
    else if (!error && !title && !message)
        return;
    
    
    switch (error.code)
    {
        case 123123: {
            
            NSString *alertString = QliqLocalizedString(@"2355-TitleDBCannotBeOpened");
            
            __weak __block typeof(self) welf = self;
            
           dispatch_async_main(^{
               
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertString
                                                                                             message:nil
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:QliqLocalizedString(@"1-ButtonOK")
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction * _Nonnull action) {
                                                                         [welf.navigationController popToRootViewControllerAnimated:NO];
                                                                     }];
                    [alertController addAction:okAction];
                    [welf.navigationController presentViewController:alertController animated:YES completion:nil];
            });
            
            [[Login sharedService] settingShouldSkipAutoLogin:YES];
            break;
        }
         default: {
            break;
        }
    }
}

@end
