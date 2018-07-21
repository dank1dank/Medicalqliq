//
//  ResetPasswordController.m
//  qliq
//
//  Created by Valerii Lider on 7/28/14.
//
//

#import "ResetPasswordController.h"
#import "ResetPassword.h"

@interface ResetPasswordController()

@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *resetPasswordButton;

@end

@implementation ResetPasswordController

- (void)dealloc
{
    self.descriptionLabel = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.resetPasswordButton setTitle:QliqLocalizedString(@"66-ButtonResetPassword") forState:UIControlStateNormal];
    
    self.descriptionLabel.text = QliqFormatLocalizedString1(@"2307-TitleResetPasswordDesacriptionFor{Email}", self.email);
}

#pragma mark - Actions -

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)onResetButton
{
    self.view.userInteractionEnabled = NO;
    [SVProgressHUD showWithStatus:NSLocalizedString(@"1917-StatusSendingRequest", nil) maskType:SVProgressHUDMaskTypeGradient];
    
    [[ResetPassword sharedService] resetPassword:self.email onCompletion:^(BOOL success, NSError *error) {
        
        [SVProgressHUD dismiss];
        self.view.userInteractionEnabled = YES;
        
        if(success)
        {
            UIAlertView_Blocks *alertView = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1195-TextRequestSent", nil)
                                                                message:NSLocalizedString(@"1196-TextThankYou", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:NSLocalizedString(@"1-ButtonOK", nil), nil];
            [alertView showWithDissmissBlock:^(NSInteger buttonIndex) {
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
        else
        {
            UIAlertView_Blocks *alertView = [[UIAlertView_Blocks alloc] initWithTitle:NSLocalizedString(@"1197-TextCannottSendRequest", nil)
                                                                message:error.localizedDescription
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:NSLocalizedString(@"1-ButtonOK", nil), nil];
            [alertView showWithDissmissBlock:^(NSInteger buttonIndex) {
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
    }];
}

@end
