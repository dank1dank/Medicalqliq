//
//  EMRUploadViewController.m
//  qliq
//
//  Created by Valerii Lider on 03/13/2017.
//
//

#import "EMRUploadViewController.h"
#import "UploadToEmrService.h"
#import "MediaFileService.h"
#import "MessageAttachment.h"
#import <WebKit/WebKit.h>
#import "UploadsMediaViewController.h"
#import "ThumbnailService.h"
#import "UIDevice-Hardware.h"
#import "AlertController.h"

#define kEMRUploadDefaultCellReuseId @"EMRUploadDefaultCellReuseId"

#define kUploadTargetKey @"uploadTargetKey"
#define kEMRPublicKey @"EMRPublicKey"
#define kFileNameKey @"fileNameKey"

#define kLoadingViewWidth 100.0f
#define kValueDefaultHeight 50.0f
#define kValueDefaultHeightCell 30.0f
#define kValueDefaultDistance 15.0f
#define kDefaultKeyboardHeight 164.0f
#define kValueStatusBarHeight 20.0f
#define kValueNavigationBarHeight 44.0f

typedef NS_ENUM(NSInteger, OptionItem) {
    OptionItemInsurance,
    OptionItemReferral,
    OptionItemFacesheet,
    OptionItemPrescription,
    OptionItemPreAuthorization,
    OptionItemConsent,
    OptionItemWound,
    OptionItemImage,
    OptionItemOther,
    OptionItemCount,
};

@interface EMRUploadViewController () <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, WKNavigationDelegate>

@property (strong, nonatomic) IBOutlet UIView *uploadImageTextView;
@property (weak, nonatomic) IBOutlet UILabel *titleImageLabel;
@property (weak, nonatomic) IBOutlet UILabel *patientNameLabel;
@property (weak, nonatomic) IBOutlet UIView *attachmentVew;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (weak, nonatomic) IBOutlet UITextField *tagTextField;
@property (weak, nonatomic) IBOutlet UITextField *typeTextField;

@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) QSPDFPreview *pdfPreview;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerViewController *playerViewController;
@property (nonatomic, strong) AVPlayer *videoPlayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;

@property (nonatomic, strong) UploadToEmrService *uploadToEmrService;
@property (nonatomic, strong) UIPickerView *typePicker;
@property (nonatomic, strong) NSArray *typeFields;
@property (nonatomic, assign) BOOL shouldAnimate;
@property (nonatomic, assign) BOOL videoPlayerAdded;
@property (nonatomic, assign) NSString *filePath;
@property (nonatomic, assign) NSString *htmlString;

@property (nonatomic, strong) UIButton *playButton;

@property (nonatomic,assign)CGFloat maxFreeWidth;
@property (nonatomic,assign)CGFloat maxFreeHeight;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *optionsViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *identifyImageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *uploadImageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *uploadButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachmentViewWidthConstraint;

@end

@implementation EMRUploadViewController

- (void)dealloc {
    self.uploadButton = nil;
    self.wkWebView = nil;
    self.loadingView = nil;
    self.uploadImageTextView = nil;
    self.titleImageLabel = nil;
    self.patientNameLabel = nil;
    self.attachmentVew = nil;
    self.tagTextField = nil;
    self.typeTextField = nil;
    self.imageView = nil;
    self.pdfPreview = nil;
    self.uploadToEmrService = nil;
    self.typePicker = nil;
    self.typeFields = nil;
    self.mediaFile = nil;
    self.patient = nil;
    self.emrTargetQliqId = nil;
    self.emrTargetPublicKey = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureController];
    [self configureTypePicker];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addKeyboardNotifications];
    
    self.optionsViewBottomConstraint.constant = kDefaultKeyboardHeight;
    self.uploadButtonWidthConstraint.constant = [UIScreen mainScreen].bounds.size.width - 2 * kValueDefaultDistance;
    [self.typeTextField becomeFirstResponder];
}

//- (void)layoutSubviews
//{
//    self.wkWebView.frame = self.attachmentVew.bounds;
//
//    CGPoint centerLoadingView = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMidY(self.view.frame));
//    centerLoadingView.x = self.view.center.x;
//    centerLoadingView.y = 0.f + (self.view.bounds.size.height - kValueStatusBarHeight - kValueNavigationBarHeight - self.uploadImageViewHeightConstraint.constant - kDefaultKeyboardHeight - self.optionsViewBottomConstraint.constant)/2 + kLoadingViewWidth/2;
//    self.loadingView.center = centerLoadingView;
////    [self setMediaFilePath:self.mediaFile.decryptedPath];
//}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self removeKeyboardNotifications];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private -

- (void)configureController {
    
    //Configute titleImageLabel
    self.titleImageLabel.text = QliqLocalizedString(@"2436-TitleUploadImageFor");
    
    //Configure patientNameLabel
    self.patientNameLabel.text = self.patient.displayName;
    
    //Configure typeTextField
    self.typeTextField.delegate = self;
    self.typeTextField.textColor = [UIColor darkGrayColor];
    self.typeTextField.placeholder = QliqLocalizedString(@"2438-TitleType");
    self.typeTextField.text = nil;
    
    //Configure tagTextField
    self.tagTextField.delegate = self;
    self.tagTextField.placeholder = QliqLocalizedString(@"2448-TitleEnterTag");
    self.tagTextField.text = nil;
    self.tagTextField.textColor = [UIColor darkGrayColor];
    
    //Configure uploadButton
    self.uploadButton.layer.cornerRadius = 10.f;
    self.uploadButton.clipsToBounds = YES;
    
    if (self.uploadToEmrService == nil) {
        self.uploadToEmrService = [[UploadToEmrService alloc] init];
    }
    
//    if (![self isImageAttachmentFile]) {

        //Configure loadingView
        [self.view addSubview:[self newLoadingView]];
        
        //Configure WKWebView
        [self configureWKWebView];
        
        __block __weak typeof(self) weakSelf = self;
        [self.mediaFile decryptAsyncCompletitionBlock:^{
            if ([weakSelf checkMediaFile:weakSelf.mediaFile])
            {
                [weakSelf setMediaFilePath:weakSelf.mediaFile.decryptedPath];
            }
        }];
//    }
    
    //Configure AttachmentView
    self.attachmentVew.backgroundColor = [UIColor whiteColor];
    self.attachmentViewWidthConstraint.constant = [UIScreen mainScreen].bounds.size.width - 2 * kValueDefaultDistance;
}

- (BOOL)checkMediaFile:(MediaFile *)mediaFile
{
    BOOL isOK = (!mediaFile || !mediaFile.decryptedPath) ? NO : YES;
    
    if (!isOK) {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"1024-TextFileIncorrect")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                 completion:nil];
    }
    return isOK;
}

- (void)configureWKWebView {

    NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";

    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];

    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];

    WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];

    wkWebConfig.userContentController = wkUController;

    wkWebConfig.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
    wkWebConfig.allowsInlineMediaPlayback = YES;
    wkWebConfig.allowsPictureInPictureMediaPlayback = NO;

    if (self.wkWebView == nil) {

        self.wkWebView = [[WKWebView alloc] initWithFrame:self.attachmentVew.bounds configuration:wkWebConfig];
    }

    self.wkWebView.navigationDelegate = self;
    [self showLoadingView:NO];
    
    [self.attachmentVew addSubview:self.wkWebView];
}

- (void)configureTypePicker {
    
    self.typeFields = @[@"",
                        QliqLocalizedString(@"2445-TitleWound"),
                        QliqLocalizedString(@"2439-TitleInsurance"),
                        QliqLocalizedString(@"2443-TitlePreAuthorization"),
                        QliqLocalizedString(@"2446-TitleImage"),
                        QliqLocalizedString(@"2440-TitleReferral"),
                        QliqLocalizedString(@"2441-TitleFacesheet"),
                        QliqLocalizedString(@"2442-TitlePrescription"),
                        QliqLocalizedString(@"2444-TitleConsent"),
                        QliqLocalizedString(@"2447-TitleOther")];
    
    self.typePicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0.f, 0.f, [UIScreen mainScreen].bounds.size.width, kKeyboardHeight)];
    self.typePicker.dataSource = self;
    self.typePicker.delegate = self;
    self.typePicker.showsSelectionIndicator = YES;
    self.typeTextField.inputView = self.typePicker;
    
    UIColor *textColor = RGBa(3, 120, 173, 1);
    
    UIToolbar *typeToolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.f, 0.f, [UIScreen mainScreen].bounds.size.width, 30.f)];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(didPressTypePickerCancelButton:)];
    
    cancelButton.tintColor = textColor;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self
                                                                  action:@selector(didPressTypePickerDoneButton:)];
    
    doneButton.tintColor = textColor;
    
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    typeToolBar.items = @[cancelButton, flexibleSpace, doneButton];
    
    self.typeTextField.inputAccessoryView = typeToolBar;
}

- (UIView *)newLoadingView {
    
    if (self.loadingView == nil) {
        self.loadingView = [[UIView alloc] init];
    }
    
    self.loadingView.frame = CGRectMake(0, 0, kLoadingViewWidth, kLoadingViewWidth);
    self.loadingView.layer.cornerRadius = 5.0f;
    self.loadingView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    
    CGPoint centerLoadingView = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMidY(self.view.frame));
    centerLoadingView.x = self.view.center.x;
    centerLoadingView.y = 0.f + (self.view.bounds.size.height - kValueStatusBarHeight - kValueNavigationBarHeight - self.uploadImageViewHeightConstraint.constant - kDefaultKeyboardHeight - self.optionsViewBottomConstraint.constant)/2 + kLoadingViewWidth/2;
    self.loadingView.center = centerLoadingView;
    
    self.loadingView.alpha = 1.0;
    
    UIActivityIndicatorView *loadingCircle = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [loadingCircle startAnimating];
    
    [self.loadingView addSubview:loadingCircle];
    
    loadingCircle.center = CGPointMake(kLoadingViewWidth/2, kLoadingViewWidth/2);
    
    return self.loadingView;
}

- (void)showLoadingView:(BOOL)shouldShow {
    if (shouldShow) {
        self.loadingView.alpha = 1.0;
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.loadingView.alpha = 0.0;
        }];
    }
}

- (void)updateAttachmentViewFrame {
    
    self.maxFreeHeight = [UIScreen mainScreen].bounds.size.height - kValueStatusBarHeight - kValueNavigationBarHeight - self.uploadImageViewHeightConstraint.constant - self.optionsViewBottomConstraint.constant - self.identifyImageViewHeightConstraint.constant;

    self.maxFreeWidth = [UIScreen mainScreen].bounds.size.width - 2 * kValueDefaultDistance;
    self.attachmentViewWidthConstraint.constant = self.maxFreeWidth;

    [self.attachmentVew setWidth:self.maxFreeWidth];
    [self.attachmentVew setHeight:self.maxFreeHeight];
    
    self.playerLayer.frame = self.attachmentVew.bounds;
    [self.attachmentVew.layer addSublayer:self.playerLayer];
    self.playButton.frame=CGRectMake(self.attachmentVew.width/2-30, self.attachmentVew.height/2-30, 60, 60);
    if (![self isImageAttachmentFile]) {
        [self.attachmentVew addSubview:self.playButton];
    }
        if ([self isImageAttachmentFile]) {
    
            CGRect frame =  CGRectMake(0.f, 0.f, 0.f, 0.f);
    
            if (self.imageView == nil) {
                self.imageView = [[UIImageView alloc] init];
    
                UIImage *image = [UIImage imageWithContentsOfFile:self.mediaFile.decryptedPath];
                self.imageView.image = image;
                self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
                frame =  CGRectMake(0.f, 0.f, self.attachmentViewWidthConstraint.constant, self.maxFreeHeight);
            }
            else {
                frame =  CGRectMake(0.f, 0.f, CGRectGetWidth(self.attachmentVew.bounds), CGRectGetHeight(self.attachmentVew.bounds));
            }
    
            [self.imageView setFrame:frame];
            [self.attachmentVew addSubview:self.imageView];
        } else {
            
        self.wkWebView.frame = self.attachmentVew.frame;
        self.wkWebView.scrollView.scrollEnabled = NO;
    
    self.wkWebView.frame =  CGRectMake(0, 0, CGRectGetWidth(self.attachmentVew.bounds), CGRectGetHeight(self.attachmentVew.bounds) + self.optionsViewBottomConstraint.constant);

            [self showLoadingView:NO];
        }
}

- (BOOL)isImageAttachmentFile {
    
    MediaFileService *sharedService = [MediaFileService getInstance];
    
    if ([sharedService isImageFileMime:self.mediaFile.mimeType FileName:self.mediaFile.encryptedPath]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)setMediaFilePath:(NSString*)documentPath {
    
    MediaFileService *sharedService = [MediaFileService getInstance];
    
    if ([sharedService isVideoFileMime:self.mediaFile.mimeType FileName:self.mediaFile.encryptedPath]) {
        
        [self showLoadingView:NO];
        
        NSURL *videoURL = [NSURL fileURLWithPath:self.mediaFile.decryptedPath];
        self.videoPlayer = [AVPlayer playerWithURL:videoURL];
        self.playerItem = [self.videoPlayer currentItem];

        self.playerViewController = [[AVPlayerViewController alloc] init];
        self.playerViewController.player = self.videoPlayer;
        self.playerViewController.view.frame = self.view.frame;

        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.videoPlayer];
        self.playerLayer.frame = self.attachmentVew.bounds;
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.playerLayer.needsDisplayOnBoundsChange = YES;
        
        [self.attachmentVew.layer addSublayer:self.playerLayer];
        
        [self configurePlayButton];
    
    } else if ([sharedService isDocumentFileMime:self.mediaFile.mimeType FileName:self.mediaFile.encryptedPath]) {
    
        NSURL *url = [NSURL fileURLWithPath:self.mediaFile.decryptedPath];
        NSURLRequest *documentRequest = [NSURLRequest requestWithURL:url];
        self.wkWebView.navigationDelegate = self;
        [self.wkWebView loadRequest:documentRequest];
        [self showLoadingView:NO];
    }
    //TODO: Can`t to use QSPDFPreview, because it in firstResponder.
    /*
     if (![[documentPath pathExtension] isEqualToString:@"pdf"]) {
     [self.webViewContent loadRequest:documentRequest];
     }
     else {
     self.pdfPreview = [[QSPDFPreview alloc] initWithFrame:CGRectMake(self.webViewContent.frame.origin.x, self.webViewContent.frame.origin.y, self.webViewContent.frame.size.width, self.webViewContent.frame.size.height)];
     [self.view addSubview:self.pdfPreview];
     [self.pdfPreview PDFOpen:documentPath withPassword:@""];
     }
     */
}

- (void) configurePlayButton {
    
    self.playButton = [[UIButton alloc] init];
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.playButton setImage:[UIImage imageNamed:@"PlayVideoNormalBlack"] forState:UIControlStateNormal];
    
    [self.playButton addTarget:self action:@selector(playButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.playButton setBackgroundColor:[UIColor lightGrayColor]];
    self.playButton.frame=CGRectMake(self.attachmentVew.width/2-30, self.attachmentVew.height/2-30, 60, 60);
    self.playButton.layer.masksToBounds = YES;
    self.playButton.layer.cornerRadius = self.playButton.width/2;
    
    [self.attachmentVew addSubview:self.playButton];
}

- (void)playButton:(id)sender {
    
    self.videoPlayerAdded = YES;
//    [self addChildViewController:self.playerViewController];
    [self.view addSubview:self.playerViewController.view];
    [self.playerViewController didMoveToParentViewController:self];
    [self didPressTypePickerCancelButton:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillHideNotification object:nil];
    [self.videoPlayer play];
}

- (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, self.maxFreeWidth, self.maxFreeHeight)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

- (void) uploadMediaFile {
    
    if (([self.typeTextField.placeholder isEqualToString:QliqLocalizedString(@"2438-TitleType")] && ([self.typeTextField.text isEqualToString:@""] || self.typeTextField.text == nil)) || [self.typeTextField.text isEqualToString:QliqLocalizedString(@"2438-TitleType")]) {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                    message:QliqLocalizedString(@"2451-TitleSelectTypeField")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                 completion:^(NSUInteger buttonIndex) {
                                     [self.typeTextField becomeFirstResponder];
                                 }];
    } else {
        
        NSString *fileName = nil;
        
        if ([self.tagTextField.text isEqualToString:@""] || [self.tagTextField.text isEqualToString:QliqLocalizedString(@"2448-TitleEnterTag")]) {
            fileName = [NSString stringWithFormat:@"%@-%f", self.typeTextField.text, self.mediaFile.timestamp];
        }
        else {
            fileName = [NSString stringWithFormat:@"%@-%@-%f", self.typeTextField.text, self.tagTextField.text, self.mediaFile.timestamp];
        }
        
        // We need to preserve the original extension so end user can open the file
        NSString *extension = [self.mediaFile.fileName pathExtension];
        if (extension.length > 0) {
            fileName = [fileName stringByAppendingFormat:@".%@", extension];
        }
        
        EmrUploadParams *uploadTarget = [UploadToEmrService uploadParamsForPatient:self.patient];
        if (self.emrTargetQliqId.length > 0) {
            uploadTarget.qliqStorQliqId = self.emrTargetQliqId;
        }
        if (self.emrTargetDeviceUuid.length > 0) {
            uploadTarget.qliqStorDeviceUuid = self.emrTargetDeviceUuid;
        }

        NSMutableDictionary *uploadsEMRInfo = [[NSMutableDictionary alloc] init];
        [uploadsEMRInfo setObject:uploadTarget forKey:kUploadTargetKey];
        [uploadsEMRInfo setObject:self.emrTargetPublicKey forKey:kEMRPublicKey];
        [uploadsEMRInfo setObject:fileName forKey:kFileNameKey];

        //Need to show 'UploadsMediaViewController' and to start EMR upload like as to QliqSTOR
        //Valerii Lider 05/23/17
        UploadsMediaViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:@"UploadsMediaViewController"];
        controller.uploadToEMR = YES;
        controller.uploadingMediaFile = self.mediaFile;
        controller.uploadsEMRInfo = [uploadsEMRInfo copy];
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void) handleUploadToEmrCompleted:(CompletitionStatus) status error:(NSError *)error
{
    dispatch_async_main(^{
        [SVProgressHUD dismiss];
    });
    
    if (error) {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                    message:error.localizedDescription
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                 completion:^(NSUInteger buttonIndex) {
                                     if (buttonIndex==1) {
                                         [self onBackAction:nil];
                                     }
                                 }];

    } else {
        [AlertController showAlertWithTitle:@"Info"
                                    message:@"The upload was sent to server"
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                 completion:nil];
    }
}

#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Actions -

#pragma mark * IBActions

- (IBAction)onBackAction:(id)sender {
    
    if (self.videoPlayerAdded) {
        DDLogSupport(@"Back from video player");
        [self.playerViewController.view removeFromSuperview];
        [self.videoPlayer pause];
        self.videoPlayerAdded = NO;
    
    } else {
        DDLogSupport(@"Back from EMRUploadViewController");
        if (self.navigationController.presentingViewController && [[self.navigationController viewControllers].firstObject isEqual:self]) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (IBAction)onUploadAction:(id)sender {
    [self uploadMediaFile];
}

#pragma mark - Notifications -

- (void)addKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)removeKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (void)keyboardWillBeShown:(NSNotification *)notification {
    
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGSize keyboardSize = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    __weak __typeof(self)welf = self;
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        
        CGFloat offset = keyboardSize.height;
        
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            offset = keyboardSize.height;
        
        isIPhoneX{
            welf.optionsViewBottomConstraint.constant = offset - 35;
        } else {
            welf.optionsViewBottomConstraint.constant = offset;
        }
        welf.attachmentVew.height = welf.attachmentVew.height - offset;
        [welf updateAttachmentViewFrame];
        if (welf.shouldAnimate) {
            [welf.view layoutIfNeeded];
        }
    } completion:nil];
}

- (void)keyboardWasShown:(NSNotification*)notification {
    
    self.shouldAnimate = YES;
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    __weak __typeof(self)welf = self;
    [UIView animateWithDuration:duration delay:0.0 options:options  animations:^{
        welf.optionsViewBottomConstraint.constant = 0.f;
        welf.attachmentVew.height = welf.attachmentVew.height + kKeyboardHeight;
        [welf updateAttachmentViewFrame];
        [welf.view layoutIfNeeded];
    } completion:nil];
}

#pragma mark - Delegates -

#pragma mark - WKWebViewDelegate methods

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [self showLoadingView:YES];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self showLoadingView:NO];
    self.wkWebView.frame = self.attachmentVew.bounds;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
    [self showLoadingView:NO];
    DDLogSupport(@"Error loading document: %@",error);

    if (!(error.code == 204)) {
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:[error localizedDescription]
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                 completion:nil];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self showLoadingView:NO];
    
    DDLogSupport(@"Error loading document: %@",error);
    [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                message:[error localizedDescription]
                            buttonTitle:nil
                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                             completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    
    if ([self.tagTextField.text isEqualToString:@""]) {
        self.tagTextField.placeholder = QliqLocalizedString(@"2448-TitleEnterTag");
    }
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if ([textField isEqual:self.typeTextField]) {
        
        if (![self.typeFields[[self.typePicker selectedRowInComponent:0]] isEqualToString:@""]) {
            self.typeTextField.text = self.typeFields[[self.typePicker selectedRowInComponent:0]];
        }
        else {
            self.typeTextField.placeholder = QliqLocalizedString(@"2438-TitleType");
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (range.location >= 10) {
        return NO;
    }
    else {
        return YES;
    }
}

#pragma mark - UIPickerViewDataSource/UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.typeFields.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.typeFields[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    if (row == 0) {
        self.typeTextField.text = nil;
    } else {
        self.typeTextField.text = self.typeFields[[self.typePicker selectedRowInComponent:0]];
    }
}

- (void)didPressTypePickerCancelButton:(UIBarButtonItem *)sender {
    [self.typeTextField resignFirstResponder];
    [self.typeTextField setText:@""];
}

- (void)didPressTypePickerDoneButton:(UIBarButtonItem *)sender {
    
    if (![self.typeFields[[self.typePicker selectedRowInComponent:0]] isEqualToString:@""]) {
        self.typeTextField.text = self.typeFields[[self.typePicker selectedRowInComponent:0]];
    }
    else {
        self.typeTextField.text = nil;
    }
    [self.typeTextField resignFirstResponder];
}

@end
