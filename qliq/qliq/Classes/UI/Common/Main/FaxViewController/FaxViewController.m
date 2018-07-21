
//  FaxViewController.m
//  qliq
//
//  Created by Valeriy Lider on 1/5/18.
//

#import "FaxViewController.h"
#import "UploadToQliqStorService.h"
#import "UploadsMediaViewController.h"

#import "THContactPickerView.h"
#import "THBubbleStyle.h"
#import "THContactPicker+Additions.h"
#import "KeyboardAccessoryViewController.h"
#import "CreateFaxContactViewController.h"
#import "BaseAttachmentViewController.h"
#import "SelectPDFViewController.h"
#import "FaxContactDBService.h"

#import "QuickMessageViewController.h"
#import "SelectContactsViewController.h"
#import "Recipients.h"
#import "UIDevice-Hardware.h"
#import "SelectContactsViewController.h"
#import "AlertController.h"

#define kValueButtonCornerRadius    15
#define kValueButtonBorderWidth     1.f
#define kButtonBorderColor                [kColorDarkBlue CGColor]
#define kBottomSendButtonConstraint 25.f;

@interface FaxViewController () <THContactPickerDelegate, SelectContactsViewControllerDelegate, UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (nonatomic, strong) IBOutlet THContactPickerView *contactPickerView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIView *infoTopView;
@property (weak, nonatomic) IBOutlet UIView *inputView;
@property (weak, nonatomic) IBOutlet UIView *inputFaxMessageView;
@property (weak, nonatomic) IBOutlet UINavigationItem *faxNavigationItem;

@property (nonatomic, strong) UITapGestureRecognizer *gestureRecognizerKeyboard;

@property (nonatomic, strong) Recipients *recipients;
@property (nonatomic, assign) SelectionType typeController;
@property (weak, nonatomic) IBOutlet QSPDFPreview *pdfPreview;
@property (nonatomic, strong) UploadToQliqStorService *uploadToQliqStorService;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomInputViewConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactPickerLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contactPickerTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottonSendButtonConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputViewHeight;


@property (nonatomic, weak) KeyboardAccessoryViewController *downView;
@property (weak, nonatomic) IBOutlet UIButton *addPDFDocument;

@end

@implementation FaxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self addKeyboardNotifications];
    [self checkMediafile];

    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: RGBa(3.f, 120.f, 173.f, 1.f)};
    
    //Gesture
    {
        self.gestureRecognizerKeyboard = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onDismisKeyboard:)];
        self.gestureRecognizerKeyboard.numberOfTapsRequired = 1;
    }
    
    self.messageLabel.text = QliqLocalizedString(@"3058-TextFaxMessageLabel");
    [self configureContactPickerView];
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.navigationController.navigationBarHidden = NO;
    
    dispatch_async_main(^{
        isIPhoneX {
            self.bottonSendButtonConstraint.constant = kBottomSendButtonConstraint;
        }
    });
    [self updateContactPickerView];
    [self checkMediafile];
}

- (void)viewWillDisappear:(BOOL)animated {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) checkMediafile {
    
    if (!self.mediaFile) {
        
        self.addPDFDocument.hidden = NO;
        [self.addPDFDocument setTitle:QliqLocalizedString(@"3057-TextAttachPDFDocument") forState:UIControlStateNormal];
        self.addPDFDocument.layer.cornerRadius = kValueButtonCornerRadius;
        self.addPDFDocument.layer.borderWidth = kValueButtonBorderWidth;
        self.addPDFDocument.layer.borderColor = kButtonBorderColor;
    } else {
        
        self.addPDFDocument.hidden = YES;
        self.infoLabel.text = self.mediaFile.fileName;
        
        BaseAttachmentViewController *baseAttachmentViewController = [BaseAttachmentViewController new];
        
        __block __weak typeof(self) weakSelf = self;
        [self.mediaFile decryptAsyncCompletitionBlock:^{
            
            if ([baseAttachmentViewController checkMediaFile:weakSelf.mediaFile])
                [weakSelf setMediaFilePath:weakSelf.mediaFile.decryptedPath];
        }];
    }
}

- (void) configureContactPickerView {
    
    self.contactPickerView.delegate = self;
    
    THBubbleStyle *style = [[THBubbleStyle alloc] initWithTextColor:kColorText
                                                        gradientTop:kColorGradientTop
                                                     gradientBottom:kColorGradientBottom
                                                        borderColor:kColorBorder
                                                        borderWidth:kDefaultBorderWidth
                                                 cornerRadiusFactor:kDefaultCornerRadiusFactor];
    
    THBubbleStyle *selectedStyle = [[THBubbleStyle alloc] initWithTextColor:kColorSelectedText
                                                                gradientTop:kColorSelectedGradientTop
                                                             gradientBottom:kColorSelectedGradientBottom
                                                                borderColor:kColorSelectedBorder
                                                                borderWidth:kDefaultBorderWidth
                                                         cornerRadiusFactor:kDefaultCornerRadiusFactor];
    
    [self.contactPickerView setBubbleStyle:style selectedStyle:selectedStyle];
    //    self.contactPickerView.textView.tintColor = kQliqBlueColor;
    //    [self.selectRecipientView setPromptLabelText:NSLocalizedString(@"2000-TitleTo:", nil)];
    [self.contactPickerView setPlaceholderLabelText:QliqLocalizedString(@"3052-TextSelectFaxRecipient")];
    [self.contactPickerView setPlaceholderAlignment];
    self.contactPickerView.forFax = YES;
    [self.contactPickerView setFont:[UIFont fontWithName:@"Helvetica Neue" size:17.f]];
}

- (void)updateContactPickerView {
    
    [self.contactPickerView removeAllContacts];
    
    if (self.recipients.count) {
        for (id contact in self.recipients.recipientsArray)
        {
            FaxContact *faxContact = contact;
            
            NSString *name = ![faxContact.contactName isEqualToString:@""] ? faxContact.contactName : faxContact.organization;
            
            NSString *contactName = [NSString stringWithFormat:@"%@ %@", name, faxContact.faxNumber];
    
            [self.contactPickerView addOneContact:faxContact withName:contactName];
        }
    }
}

- (void)setMediaFilePath:(NSString*)documentPath {
    
    [self.pdfPreview PDFOpen:documentPath withPassword:@""];
}

#pragma mark * THContactPickerTextView Delegate

- (void)contactPickerTextViewDidChange:(NSString *)textViewText {
    
    self.recipients.name = @"";
    self.recipients.isPersonalGroup = NO;
    
    SelectContactsViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
    controller.firstFilterCharacter = textViewText;
    controller.faxSearch = YES;
    controller.delegate = self;
    controller.participants = [self.recipients.recipientsArray mutableCopy];
    controller.typeController = STForNewConversation;
    
    [self.navigationController pushViewController:controller animated:YES];
    controller = nil;
    
    [self.contactPickerView resignFirstResponder];
    
    __weak __block typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0.0 options:nil animations:^{
        [weakSelf.view layoutSubviews];
    } completion:nil];
}

- (void) contactPickerDidResize:(THContactPickerView *)contactPickerView {
    
    [self.view layoutSubviews];
}

- (void)contactPickerDidRemoveContact:(id)contact
{
    self.recipients.name = @"";
    self.recipients.isPersonalGroup = NO;
    [self.recipients removeRecipient:contact];
}

- (CGFloat)getContactPickerWidth
{
    CGFloat width = 0.f;
    CGRect rect = CGRectZero;
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        rect = CGRectMake(0, 0, MAX(bounds.size.height, bounds.size.width), MIN(bounds.size.height, bounds.size.width));
    }
    else if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
    {
        rect = CGRectMake(0, 0, MIN(bounds.size.height, bounds.size.width), MAX(bounds.size.height, bounds.size.width));
    }
    
    width = rect.size.width - self.contactPickerLeadingConstraint.constant - self.contactPickerTrailingConstraint.constant;
    
    return width;
}

- (Recipients *)recipients {
    if (_recipients == nil) {
        _recipients = [[Recipients alloc] init];
    }
    
    return _recipients;
}

#pragma mark * SelectContactsViewDelegate

- (void)didSelectedParticipants:(NSMutableArray *)participants {
    
    [self.recipients.recipientsArray removeAllObjects];
    [self.recipients.recipientsArray addObjectsFromArray:participants];
}

#pragma mark * GestureRecognizers Actions

- (void)onDismisKeyboard:(UITapGestureRecognizer *)tap {
    [self.view endEditing:YES];
}

#pragma mark * Managing Notifications *

- (void)addKeyboardNotifications
{
    DDLogSupport(@"Adding Keyboard Notifications");
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
}

- (void)removeKeyboardNotifications
{
    DDLogSupport(@"Removing Keyboard Notifications");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

#pragma mark - Keyboard

- (void)keyboardWillBeShown:(NSNotification *)notification {
    
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    __weak __block typeof(self) weakSelf = self;
    dispatch_async_main(^{
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            
            weakSelf.bottomInputViewConstraint.constant = keyboardSize.height;
            
            NSUInteger pdfViewHeight = kScreenHeight - weakSelf.infoTopView.height - keyboardSize.height - weakSelf.inputView.height - 64;
            if ((pdfViewHeight < 55) && !self.mediaFile) {
                weakSelf.inputViewHeight.constant = weakSelf.inputViewHeight.constant - (55 - pdfViewHeight);
            }
            [weakSelf.view layoutIfNeeded];
        } completion:nil];
    });

    [self.view addGestureRecognizer:self.gestureRecognizerKeyboard];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    
        UIViewAnimationCurve curve = [aNotification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
        UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
        NSTimeInterval duration = [aNotification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        __weak __block typeof(self) weakSelf = self;
    dispatch_async_main(^{
        [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
            
            weakSelf.bottomInputViewConstraint.constant = 0;

            if (!self.mediaFile) {
                weakSelf.inputViewHeight.constant = 210;
            }
            
            [weakSelf.view layoutIfNeeded];
        } completion:nil];
    });
    
    [self.view removeGestureRecognizer:self.gestureRecognizerKeyboard];
}

#pragma mark - Actions

- (IBAction)sendFaxButton:(id)sender {
    
    if (self.recipients.count && self.mediaFile) {
        for (id contact in self.recipients.recipientsArray) {
            
            UploadsMediaViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:@"UploadsMediaViewController"];
            controller.faxUpload = YES;
            controller.uploadingMediaFile = self.mediaFile;
            controller.faxContact = contact;
            controller.faxBody = self.messageTextView.text;
            
            [self.navigationController pushViewController:controller animated:YES];
        }
    } else {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:self.mediaFile ? QliqLocalizedString(@"3050-TextNotSelectFaxContact") : QliqLocalizedString(@"3051-TextNotSelectPDFfile")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                 completion:nil];
    }
}

- (IBAction)addPDFDocumentButton:(id)sender {
    DDLogSupport(@"On add PDF Document");
    
    __weak __block typeof(self) welf = self;
    SelectPDFViewController *selectPDFViewController = [kMainStoryboard instantiateViewControllerWithIdentifier:@"SelectPDFViewController"];
    selectPDFViewController.showNewPDFButton = YES;
    selectPDFViewController.selectPDFCallBack = ^(MediaFile *pdf){
        
        if([pdf decrypt]){
            
            self.mediaFile = pdf;
            [welf.navigationController popToViewController:self animated:YES];
        }
    };
    [self.navigationController pushViewController:selectPDFViewController animated:YES];
}

- (IBAction)onBack:(id)sender {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end

