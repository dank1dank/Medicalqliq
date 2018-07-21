//
//  InvitationNonQliqUserViewController.m
//  qliq
//
//  Created by Spire Ivanov on 04/01/16.
//
//

#import "InvitationNonQliqUserViewController.h"

typedef NS_ENUM(NSInteger, TextFieldType) {
    TextFieldTypeEnterEmail = 1,
    TextFieldTypeSubject = 2
};

@interface InvitationNonQliqUserViewController () <UITextFieldDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *enterEmailTextField;
@property (weak, nonatomic) IBOutlet UITextField *subjectTextField;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;


@end

@implementation InvitationNonQliqUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.messageTextView.text = @"";
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

- (UIToolbar *)getAccessoryView {
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil)
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(onTap)];
    doneButton.tintColor = kColorDarkBlue;
    
    UIToolbar *accessoryToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.frame.size.width, 30.f)];
    accessoryToolbar.items = @[flexibleSpace, doneButton];
    
    
    return accessoryToolbar;
}

#pragma mark - Actions

- (void)onTap {
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

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    return YES;
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
