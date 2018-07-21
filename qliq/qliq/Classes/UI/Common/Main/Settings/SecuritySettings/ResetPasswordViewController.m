//
//  ResetPasswordViewController.m
//  qliq
//
//  Created by Valeriy Lider on 20.11.14.
//
//

#import "ResetPasswordViewController.h"
#import "ResetPassword.h"

#import "AlertController.h"

@interface ResetPasswordViewController ()

@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;


@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@end

@implementation ResetPasswordViewController

- (void)configureDefaultText {
    
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"107-ButtonResetPassword");
    
    [self.resetButton setTitle:QliqLocalizedString(@"107-ButtonResetPassword") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    self.textView.text = QliqFormatLocalizedString1(@"2087-TitleResetPassfordFor{email}", self.email);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

- (void)startWaiting
{
    self.view.userInteractionEnabled = NO;
    [SVProgressHUD showWithStatus:NSLocalizedString(@"1917-StatusSendingRequest", nil) maskType:SVProgressHUDMaskTypeGradient];
}

- (void)stopWaiting
{
    [SVProgressHUD dismiss];
    self.view.userInteractionEnabled = YES;
}

#pragma mark - IBActions -

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onResetPassword:(id)sender {
    
    [self startWaiting];
    [[ResetPassword sharedService] resetPassword:self.email onCompletion:^(BOOL success, NSError *error){
        
        if(success) {
            [self stopWaiting];
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1195-TextRequestSent")
                                        message:QliqLocalizedString(@"1196-TextThankYou")
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:nil];

        } else {
            [self stopWaiting];
            
            [AlertController showAlertWithTitle:QliqLocalizedString(@"1197-TextCannottSendRequest")
                                        message:error.localizedDescription
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                     completion:nil];
        }
    }];
}

@end
