//
//  InvitationNonQliqUserViewController.m
//  qliq
//
//  Created by Valerii Lider on 04/01/16.
//
//

#import "SendToNonQliqUserViewController.h"
#import "QliqUserDBService.h"
#import "SendMessageToNonQliqUserService.h"
#import "ConversationViewController.h"
#import "QliqJsonSchemaHeader.h"
#import "QliqConnectModule.h"
#import "ConversationViewController.h"
#import "AlertController.h"

typedef NS_ENUM(NSInteger, TextFieldType) {
    TextFieldTypeEnterEmail = 1,
    TextFieldTypeSubject = 2
};

#define kmessageTextViewBottomConstraintConstant 20.f

@interface SendToNonQliqUserViewController () <UITextFieldDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@property (weak, nonatomic) IBOutlet UILabel *title1Label;


@property (weak, nonatomic) IBOutlet UITextField *enterEmailTextField;
@property (weak, nonatomic) IBOutlet UITextField *subjectTextField;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageTextViewBottomConstraint;

@end

@implementation SendToNonQliqUserViewController

- (void)dealloc {
    self.enterEmailTextField = nil;
    self.subjectTextField = nil;
    self.messageTextView = nil;
}

- (void)configureDefaultText {
    self.navigationLeftTitleLabel.text = QliqLocalizedString(@"2101-TitleTextNon-QliqUser");
    [self.sendButton setTitle:QliqLocalizedString(@"10-ButtonSend") forState:UIControlStateNormal];
    
    self.title1Label.text = QliqLocalizedString(@"2149-TitleSendSecureTextEmail/Mobile");
    
    self.enterEmailTextField.placeholder = QliqLocalizedString(@"2150-TitleEnterEmail/Mobile");
    
    self.subjectTextField.placeholder = QliqLocalizedString(@"2032-TitleSubject");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureDefaultText];
    
    self.enterEmailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.enterEmailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    self.messageTextView.text = @"";
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyboard)];
    [self.view addGestureRecognizer:tapGesture];

    //Notifications
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    [self addKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    [self removeKeyboardNotifications];
    [self resignKeyboard];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Notifications

- (void)addKeyboardNotifications {
    DDLogSupport(@"Adding Keyboard Notifications");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeKeyboardNotifications {
    DDLogSupport(@"Removing Keyboard Notifications");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillBeShown:(NSNotification*)notification {
    
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        
        CGFloat offset = keyboardSize.height;
        
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            offset = keyboardSize.height;
        
        offset += 10.f;
        
        self.messageTextViewBottomConstraint.constant = offset;
        
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (void)keyboardWillBeHidden:(NSNotification*)notification {
    
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration delay:0.0 options:options  animations:^{
        
        self.messageTextViewBottomConstraint.constant = kmessageTextViewBottomConstraintConstant;
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

#pragma mark - Private

- (UIToolbar *)getAccessoryView {
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"38-ButtonDone", nil)
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(resignKeyboard)];
    doneButton.tintColor = kColorDarkBlue;
    
    UIToolbar *accessoryToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.frame.size.width, 30.f)];
    accessoryToolbar.items = @[flexibleSpace, doneButton];
    
    return accessoryToolbar;
}

#pragma mark - Actions

- (void)resignKeyboard {
    if ([self.enterEmailTextField isFirstResponder]) {
        [self.enterEmailTextField resignFirstResponder];
    }
    else if ([self.subjectTextField isFirstResponder]) {
        [self.subjectTextField resignFirstResponder];
    }
    else if ([self.messageTextView isFirstResponder]) {
        [self.messageTextView resignFirstResponder];
    }
}

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSend:(id)sender {
    DDLogSupport(@"on send to nonQliq user pressed");
    
    [self resignKeyboard];
    
    QliqUser *contact = [[QliqUser alloc] init];
    QliqUser *existingUser = nil;
    
    if (isValidEmail(self.enterEmailTextField.text)) {
        contact.email = self.enterEmailTextField.text;
        existingUser = [[QliqUserDBService sharedService] getUserWithEmail:contact.email];
    }
    else if (isValidPhone(self.enterEmailTextField.text)) {
        contact.mobile = self.enterEmailTextField.text;
        existingUser = [[QliqUserDBService sharedService] getUserWithMobile:contact.mobile];
    }
    else if ([self.enterEmailTextField.text length] == 0) {
        [self resignKeyboard];
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1101-TextEnterValidEmailOrMobile")
                                    message:nil
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];

        return;
    } else {
        [self resignKeyboard];
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1199-TextEmailOrMobileNotValid")
                                    message:nil
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
        
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:NSLocalizedString(@"%@ is neither a valid email nor a valid phone number", nil), self.enterEmailTextField.text]];
        return;
    }
    
    if (self.messageTextView.text.length == 0) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"1918-StatusPleaseEnterMessageText", nil)];
        return;
    }
    
    if (existingUser == nil) {
        SendMessageToNonQliqUserService *service = [[SendMessageToNonQliqUserService alloc] initWithEmail:contact.email orMobile:contact.mobile withSubject:self.subjectTextField.text message:self.messageTextView.text];
        [service callServiceWithCompletition:^(CompletitionStatus status, id result, NSError *error) {
            if (status == CompletitionStatusSuccess) {
                DDLogSupport(@"SendMessageToNonQliqUserService request - success");
                NSDictionary *resultDict = (NSDictionary *)result;
                NSString *messageUuid = [resultDict objectForKey:CALL_ID];
                NSString *conversationUuid = [resultDict objectForKey:CONVERSATION_ID];
                QliqUser *newUser = [resultDict objectForKey:QLIQ_USER];
                [self sendMessageToUser:newUser withMessageUuid:messageUuid withConversationUuid:conversationUuid];
            }
            else {
                // TODO: show error. Look into API service base for error dict processing
            }
        }];
    }
    else {
        [self sendMessageToUser:existingUser withMessageUuid:nil withConversationUuid:nil];
    }
}

- (void)sendMessageToUser:(QliqUser *)user withMessageUuid:(NSString *)messageUuid withConversationUuid:(NSString *)conversationUuid {
    
    DDLogSupport(@"Sending message to nonQliq user");
    
    Recipients *recipients = [[Recipients alloc] init];
    [recipients addRecipient:user];
   
    ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
    controller.recipients = recipients;
    controller.isBroadcastConversation = NO;
    [controller sendMessageInNewConversation:self.messageTextView.text toRecipients:recipients withSubject:self.subjectTextField.text conversationUuuid:conversationUuid messageUuid:messageUuid];

    [self.navigationController popViewControllerAnimated:NO];
    [appDelegate.navigationController pushViewController:controller animated:YES];
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    textView.inputAccessoryView = [self getAccessoryView];
    
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange {
    return YES;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.inputAccessoryView = [self getAccessoryView];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}

@end
