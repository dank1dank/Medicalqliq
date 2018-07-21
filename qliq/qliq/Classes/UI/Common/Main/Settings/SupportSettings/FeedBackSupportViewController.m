//
//  FeedBackViewController.m
//  qliq
//
//  Created by Valeriy Lider on 24.11.14.
//
//

#import "FeedBackSupportViewController.h"
#import "SendFeedbackService.h"
#import "ReportIncidentService.h"
#import "DBUtil.h"

#import "AlertController.h"

#define kValueAlbumViewBottomOffset 46.f

#define kValueCommentLabelTop 5.f
#define kValueSendButtonBot 5.f

@interface FeedBackSupportViewController ()
<
UITextViewDelegate,
UITextFieldDelegate
>

/**
 IBOutlet
 */
@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *navigationRightTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorLogTitleLabel;


@property (weak, nonatomic) IBOutlet UIView *subjectView;
@property (weak, nonatomic) IBOutlet UILabel *feedbackLabel;
@property (weak, nonatomic) IBOutlet UITextField *subjectTextField;
@property (weak, nonatomic) IBOutlet UITextView *commentaryTextView;
@property (weak, nonatomic) IBOutlet UIView *waterMarkView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

/* Constraint */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomSendButtonConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topCommentsLabelConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightCommentsLabelConstraint;

@end

@implementation FeedBackSupportViewController

- (void)configureDefaultText {
    
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"2030-TitleSettings");
    
    self.navigationRightTitleLabel.text = QliqLocalizedString(@"2031-TitleReportFeedback");
    
    self.subjectTitleLabel.text = QliqLocalizedString(@"2032-TitleSubject");
    
    self.commentsTitleLabel.text = QliqLocalizedString(@"2033-TitleCommentsTitle");
    
    self.errorLogTitleLabel.text = QliqLocalizedString(@"2034-TitleErrorLog");
    
    [self.sendButton setTitle:QliqLocalizedString(@"10-ButtonSend") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    switch (self.reportType)
    {
        case ReportTypeError: {
        
            self.waterMarkView.hidden = NO;
            self.feedbackLabel.text = QliqLocalizedString(@"2023-TitleReportError");
            
            break;
        }
            
        case ReportTypeFeedback: {
            
            self.waterMarkView.hidden = YES;
            self.feedbackLabel.text = QliqLocalizedString(@"2022-TitleSendFeedback");
            break;
        }
            
        default: {
            
            self.waterMarkView.hidden = YES;
            self.feedbackLabel.text = QliqLocalizedString(@"2031-TitleReportFeedback");
            break;
        }
    }
    
    //Constraint
    {
        self.bottomSendButtonConstraint.constant = kValueAlbumViewBottomOffset;
    }
        
    /**
     Add Gesture For hide Keyboard
     */
    {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self.view addGestureRecognizer:tapRecognizer];
        
        UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        [swipeRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];
        [self.view addGestureRecognizer:swipeRecognizer];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    if ([self.subjectTextField resignFirstResponder])
        [self.subjectTextField becomeFirstResponder];
    
    [self addKeyboardNotificationHandling];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    [self removeKeyboardNotificationHandling];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Notifications -

- (void)addKeyboardNotificationHandling
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardDidShowNotification:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}

- (void)removeKeyboardNotificationHandling
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (void)onKeyboardWillShowNotification:(NSNotification *)notification
{
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    NSValue *value = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyBoardFrame = [value CGRectValue];
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        
        self.topCommentsLabelConstraint.constant = -(self.heightCommentsLabelConstraint.constant);
        self.bottomSendButtonConstraint.constant = keyBoardFrame.size.height + kValueSendButtonBot;
        [self.view layoutIfNeeded];
        
    } completion:nil];
    
}

- (void)onKeyboardWillHideNotification:(NSNotification *)notification
{
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        
        self.topCommentsLabelConstraint.constant = kValueCommentLabelTop;
        self.bottomSendButtonConstraint.constant = kValueSendButtonBot;
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (void)onKeyboardDidShowNotification:(NSNotification *)notification
{
}


#pragma mark - IBActions -

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSend:(id)sender
{
    if (self.subjectTextField.text.length > 0 && self.commentaryTextView.text.length > 0) {
        
        switch (self.reportType)
        {
            case ReportTypeFeedback: {
                
                [self sendReportWithDatabase:NO];
                break;
            }
                
            case ReportTypeError: {
                
                [AlertController showAlertWithTitle:QliqLocalizedString(@"1079-TextMoreInformation")
                                            message:QliqLocalizedString(@"1080-TextAskSendDataBase")
                                        buttonTitle:QliqLocalizedString(@"3-ButtonYes")
                                  cancelButtonTitle:QliqLocalizedString(@"2-ButtonNo")
                                         completion:^(NSUInteger buttonIndex) {
                                             
                                             if (buttonIndex == 0) {
                                                 [self sendReportWithDatabase:YES];
                                             }
                                             else {
                                                 [self sendReportWithDatabase:NO];
                                             }
                                         }];
                break;
            }
        }
    } else {
        [AlertController showAlertWithTitle:QliqLocalizedString (@"1023-TextError")
                                    message:QliqLocalizedString(@"10833-TextFillFields")
                                buttonTitle:QliqLocalizedString(@"3-ButtonYes")
                          cancelButtonTitle:QliqLocalizedString(@"2-ButtonNo")
                                 completion:nil];
    }
}

#pragma mark - Gesture action

- (void)handleTap:(UITapGestureRecognizer*)sender
{
    [self.subjectTextField resignFirstResponder];
    [self.commentaryTextView resignFirstResponder];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *)sender
{
    if (sender.direction == UISwipeGestureRecognizerDirectionDown)
    {
        [self.subjectTextField resignFirstResponder];
        [self.commentaryTextView resignFirstResponder];
    }
}

#pragma mark - Private Methods

- (void)sendReportWithDatabase:(BOOL)includeDatabase
{
    [SVProgressHUD showWithStatus:QliqLocalizedString(@"1907-StatusSending") maskType:SVProgressHUDMaskTypeGradient];
    
    self.view.userInteractionEnabled = NO;
    
    __block QliqAPIService *service = nil;
    
    switch (self.reportType) {
            
        case ReportTypeFeedback: {
            service = [[SendFeedbackService alloc] initWithMessage:self.commentaryTextView.text andSubject:self.subjectTextField.text notifyUser:YES];
            break;
        }
            
        case ReportTypeError: {
            NSString *message = self.commentaryTextView.text;
            NSString *subject = self.subjectTextField.text;
            //dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            service = [[ReportIncidentService alloc] initWithDefaultFilesAndDatabase:includeDatabase andLogDatabase:YES andMessage:message andSubject:subject isNotifyUser:YES];
            //});
            break;
        }
    }
    
    [service callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
        
        [SVProgressHUD dismiss];
        self.view.userInteractionEnabled = YES;
        NSString * alertMessage = nil;
        NSString * alertTitle = nil;
        BOOL shouldPopViewController = NO;
        
        if (!error) {
            
            alertTitle = NSLocalizedString(@"1081-TextSuccess", nil);
            
            if (self.reportType == ReportTypeFeedback) {
                alertMessage = NSLocalizedString(@"1082-TextThanksForFeedback", nil);
            } else {
                alertMessage = NSLocalizedString(@"1083-TextErrorReported", nil);
                if (result)
                    alertMessage = [alertMessage stringByAppendingFormat:NSLocalizedString(@"\nReport #%@", nil),result];
            }
            shouldPopViewController = YES;
            
        } else {
            
            alertTitle = NSLocalizedString(@"1023-TextError", nil);
            alertMessage = [error localizedDescription];
        }
        
        [AlertController showAlertWithTitle:alertTitle
                                    message:alertMessage
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:^(NSUInteger buttonIndex) {
                                     if (shouldPopViewController)
                                         [self.navigationController popViewControllerAnimated:YES];
                                 }];
        
        DDLogSupport(@"ended with status: %d, error: %@",status, error);
    }];
}

//- (void)updateSendButton {
//
//    self.sendButton.enabled = self.subjectTextField.text.length > 0 && self.commentaryTextView.text.length > 0;
//
//    if (!self.sendButton.enabled) {
//
//        [self showAlertWithTitle:QliqLocalizedString (@"1023-TextError")
//                         message:@"Please, fill in all the fields"
//                     buttonTitle:QliqLocalizedString (@"1-ButtonOK")
//                     otherButton:nil
//                      completion:nil];
//    }
//}
#pragma mark - UITextFieldDelegate

//- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
//
//    self.sendButton.enabled = self.subjectTextField.text.length > 0 && [self.commentaryTextView.text stringByReplacingCharactersInRange:range withString:text].length > 0;
//
//    return YES;
//}

//- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
//
//    if( [string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location == NSNotFound )
//    {
//        self.sendButton.enabled = self.commentaryTextView.text.length > 0 && [self.subjectTextField.text stringByReplacingCharactersInRange:range withString:string].length > 0;
//        return YES;
//    }
//
//    [self.commentaryTextView becomeFirstResponder];
//    [self.commentaryTextView scrollRectToVisible:CGRectMake(0, self.commentaryTextView.contentSize.height-1, 1, 1) animated:YES];
//    [self updateSendButton];
//
//    return NO;
//}

//- (void) textFieldDidBeginEditing:(UITextField *)textField {
//    [self updateSendButton];
//}
//
//- (void) textFieldDidEndEditing:(UITextField *)textField {
//    [self updateSendButton];
//}


@end
