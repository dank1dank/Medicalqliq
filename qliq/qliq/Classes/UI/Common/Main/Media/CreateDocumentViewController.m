//
//  CreateDocumentViewController.m
//  qliq
//
//  Created by Valeriy Lider on 24.12.14.
//
//

#import "CreateDocumentViewController.h"
#import "MediaFile.h"
#import "ThumbnailService.h"
#import "UIDevice-Hardware.h"

@interface CreateDocumentViewController ()

@property (weak, nonatomic) IBOutlet UILabel *navigationLeftTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UITextView *textView;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomTextViewConstraint;

/* Constraints for iPhoneX */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewTrailingConstraint;

@end

@implementation CreateDocumentViewController

- (void)configuerDefaultText {
    self.navigationLeftTitleLabel.text =QliqLocalizedString(@"49-ButtonBack");
    [self.saveButton setTitle:QliqLocalizedString(@"44-ButtonSave") forState:UIControlStateNormal];
    self.descriptionLabel.text = QliqLocalizedString(@"2128-TitleCreateDocumentDescription");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*Change constraint for iPhone X*/
    __block __weak typeof(self) weakSelf = self;
    dispatch_async_main(^{
        isIPhoneX {
            [[NSNotificationCenter defaultCenter]addObserver:weakSelf selector:@selector(rotated:) name:UIDeviceOrientationDidChangeNotification object:nil];
        }
    });
    
    [self configuerDefaultText];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnScreen)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    [self addKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES];
//    [self removeKeyboardNotifications];
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Managing Notifications

- (void)addKeyboardNotifications
{
    DDLogSupport(@"Adding Keyboard Notifications in CreateDocumentViewController");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeShown:) name:@"UIKeyboardWillShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)removeKeyboardNotifications
{
    DDLogSupport(@"Removing Keyboard Notifications in CreateDocumentViewController");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIKeyboardWillShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)keyboardWillBeShown:(NSNotification*)notification
{
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        
        CGFloat offset = keyboardSize.height;
        
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            offset = keyboardSize.height;
        
        self.bottomTextViewConstraint.constant = offset + 10.f;
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

- (void)keyboardWillBeHidden:(NSNotification*)notification
{
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration delay:0.0 options:options  animations:^{
        
        self.bottomTextViewConstraint.constant = 20.f;
        [self.view layoutIfNeeded];
        
    } completion:nil];
}

#pragma mark - Gesture Recognizers

- (void)didTapOnScreen
{
    [self.textView endEditing:YES];
}

- (void)rotated:(NSNotification*)notification {
    
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        self.textViewLeadingConstraint.constant = self.textViewLeadingConstraint.constant +35;
        self.textViewTrailingConstraint.constant = self.textViewTrailingConstraint.constant -35;
    } else {
        self.textViewLeadingConstraint.constant = self.textViewLeadingConstraint.constant -35;
        self.textViewTrailingConstraint.constant = self.textViewTrailingConstraint.constant +35;
    }
}

#pragma mark - IBActions

- (IBAction)onBack:(id)sender {
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onSave:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(createDocumentViewController:didCreateddMediaFile:)] && self.textView.text.length != 0)
    {
        MediaFile *mediaFile = [[MediaFile alloc] init];
        mediaFile.fileName = [MediaFile generateDocumentFilename];
        mediaFile.decryptedPath = [NSString stringWithFormat:@"%@%@",kDecryptedDirectory,mediaFile.fileName];
        mediaFile.mimeType = @"txt";
        mediaFile.timestamp = [NSDate date].timeIntervalSince1970;
        
        //Request for thumbnail to cache it
        [[ThumbnailService sharedService] thumbnailForMediaFile:mediaFile];
        NSData *data = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
        [mediaFile saveDecryptedData:data];
        [mediaFile encrypt];
        [mediaFile save];
        
//        [self.delegate createDocumentViewController:self didCreateddMediaFile:mediaFile];
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
