//
//  DocumentView.m
//  test
//
//  Created by Я on 23.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocumentAttachmentViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <QliqSign/QSPDFPreview.h>
#import "MediaFileDBService.h"
#import "NotificationUtils.h"
#import "ConversationViewController.h"
#import "MainViewController.h"

#import "FaxViewController.h"
#import "UploadsMediaViewController.h"

#import "MediaFileUploadDBService.h"
#import "UIDevice-Hardware.h"

#import "UploadDetailView.h"
#import "TimestampCell.h"

#import "AlertController.h"

#define kLoadingViewWidth 100.0f
#define kValueDefaultHeaderHeight 24.f
#define kValueDefaultDistance 20.f
#define kBlueColor RGBa(0, 120, 174, 1)

@interface DocumentAttachmentViewController() <UIWebViewDelegate>

//IBOutlets
@property (weak, nonatomic) IBOutlet UIButton *removeButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIWebView *contentWebView;
@property (weak, nonatomic) IBOutlet UIView *detailView;
@property (weak, nonatomic) IBOutlet UIButton *uploadAgainButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet QSPDFPreview *pdfPreview;
@property (weak, nonatomic) IBOutlet UIView *buttonsTopView;

//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *removeButtonXCenterConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentWebViewBottomConstraint;

//Data
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UploadDetailView *uploadDetailView;

@property (nonatomic, strong) NSString *documentPath;

@end

@implementation DocumentAttachmentViewController

- (void)dealloc {
    self.removeButton = nil;
    self.shareButton = nil;
    self.contentWebView = nil;
    self.detailView = nil;
    self.uploadAgainButton = nil;
    self.backButton = nil;
    self.loadingView = nil;
    self.pdfPreview = nil;
    self.uploadDetailView = nil;
    self.upload = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureController];
}

- (void)layoutSubviews
{
    self.loadingView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRotate:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark - Private -

- (void)configureController
{
    //Configure contentWebView
    self.contentWebView.delegate = self;
    self.contentWebView.scalesPageToFit = YES;

    //Configure buttons
    self.shareButton.hidden = self.upload || self.viewMode == ViewModeForPresentAttachment;
    self.uploadAgainButton.hidden = ![self.upload isFailed];
    self.removeButton.hidden = !self.shouldShowDeleteButton;
    
    [self cofigureButton:self.shareButton withColor:[UIColor blackColor] withBackgroundColor:NO];
    [self cofigureButton:self.backButton withColor:[UIColor blackColor] withBackgroundColor:NO];
    [self cofigureButton:self.removeButton withColor:[UIColor blackColor] withBackgroundColor:NO];

    if (!self.uploadAgainButton.hidden) {
        //Configure uploadAgainButton
        [self.uploadAgainButton setTitle:QliqLocalizedString(@"2463-TitleUploadAgain") forState:UIControlStateNormal];
        [self.uploadAgainButton setTitleColor:kBlueColor forState:UIControlStateNormal];
        self.uploadAgainButton.tintColor = kBlueColor;
        self.uploadAgainButton.clipsToBounds = YES;
        self.uploadAgainButton.layer.masksToBounds = YES;
        self.uploadAgainButton.layer.cornerRadius = 12.f;
        [[self.uploadAgainButton layer] setBorderWidth:1.5f];
        [[self.uploadAgainButton layer] setBorderColor:kBlueColor.CGColor];

        //Configure center position remove button
        self.removeButtonXCenterConstraint.constant = self.removeButtonXCenterConstraint.constant - (2* kValueDefaultDistance - self.uploadAgainButton.frame.size.width - self.removeButton.frame.size.width)/4;
    }
    else {
        self.removeButtonXCenterConstraint.constant = 0.f;
    }
    
    __block __weak typeof(self) weakSelf = self;
    if (self.mediaFile) {
        
        //Configure loadingView
        [self.view addSubview:[self newLoadingView]];
        
        self.uploadDetailView.hidden = YES;
        [self.mediaFile decryptAsyncCompletitionBlock:^{
            if ([weakSelf checkMediaFile:weakSelf.mediaFile])
            {
                [weakSelf setMediaFilePath:weakSelf.mediaFile.decryptedPath];
            }
        }];
        self.uploadDetailView.hidden = YES;
    }
    else if (self.upload ) {
        [self configureUploadDetailView];
        [self attemptToOpen:self.upload.mediaFile];
        self.uploadDetailView.hidden = NO;
        

    }
}

- (void)configureUploadDetailView {
 
    self.detailView.hidden = NO;

    self.uploadDetailView = [[UploadDetailView alloc] init];
    [self.uploadDetailView loadUploadEventsForUploadFile:self.upload];
    self.uploadDetailView.upload = self.upload;
    [self.detailView addSubview:self.uploadDetailView];
    [self.detailView setFrame:self.uploadDetailView.bounds];

    [self.view layoutIfNeeded];
}

- (UIView *)newLoadingView {

    if (self.loadingView == nil) {
        self.loadingView = [[UIView alloc] init];
    }
    
    self.loadingView.frame = CGRectMake(0, 0, kLoadingViewWidth, kLoadingViewWidth);
    self.loadingView.layer.cornerRadius = 5.0f;
    self.loadingView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    self.loadingView.center = self.view.center;
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
    }
    else {
        [UIView animateWithDuration:0.2 animations:^{
            self.loadingView.alpha = 0.0;
        }];
    }
}

- (void)setMediaFilePath:(NSString*)documentPath
{
    //For reload PDF file, if device was rotated
    self.documentPath = documentPath;
    
    NSURL *url = [NSURL fileURLWithPath:documentPath];
    NSURLRequest *documentRequest = [NSURLRequest requestWithURL:url];
    
    [self.contentWebView loadRequest:documentRequest];

    if ([self isPDFFile:documentPath]) {
        [self didRotate:nil];
        self.pdfPreview.hidden = NO;
        [self.pdfPreview PDFOpen:documentPath withPassword:@""];
    }
}

- (BOOL)isPDFFile:(NSString *)documentPath {
    
    if ([[documentPath pathExtension] isEqualToString:@"pdf"]) {
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark - Notifications -

- (void) didRotate:(NSNotification *)notification {
    
    if (!self.upload) {
        //Hide detailView if opens PDF from media (not Uploads)
        self.detailViewHeightConstraint.constant = 0;
    } else {
        self.detailViewHeightConstraint.constant = 100;
    }
    
    //Need to update width for uploadDetailView if device was rotated
    self.uploadDetailView = [self.uploadDetailView initWithFrame:self.detailView.frame];
    
    self.contentWebViewBottomConstraint.constant = self.detailViewHeightConstraint.constant;
    if (self.documentPath){
        //Need to update PDF width if device was rotated
        [self.pdfPreview PDFOpen:self.documentPath withPassword:@""];
    }
    [self.view layoutIfNeeded];
}

#pragma mark - Actions -

#pragma mark * IBActions

- (IBAction)didTapBackButton:(id)sender {
    
    if (self.showForQliqSign) {
        if(self.returnToFaxView){
            // If this preview PDF document for Fax need to open Fax & Sign with mediafile
            FaxViewController *faxViewController = [kMainStoryboard instantiateViewControllerWithIdentifier:@"FaxViewController"];
            faxViewController.mediaFile = self.mediaFile;

            [self.navigationController pushViewController:faxViewController animated:YES];
        } else if (self.needToOpenQliqSTOR) {
            UploadsMediaViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:@"UploadsMediaViewController"];
            controller.uploadToEMR = NO;
            controller.uploadingMediaFile = self.mediaFile;
            [appDelegate.navigationController pushViewController:controller animated:YES];
        } else {
            self.showForQliqSign = NO;
            for (id controller in appDelegate.navigationController.viewControllers) {
                if ([controller isKindOfClass:[MainViewController class]]) {
                    [self.navigationController popToViewController:controller animated:YES];
                    [NSNotificationCenter postNotificationToMainThread:OpenMediaControllerNotification  withObject:nil userInfo:nil];
                    break;
                }
            }
        }
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)didTapRemoveButton:(id)sender
{
    [self removeMediaFileAndAttachment];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)didTapShareButton:(id)sender {
    [self shareFile:self.contentWebView.viewPrintFormatter];
}

- (IBAction)didTapUploadAgainButton:(id)sender {

    [[NSNotificationCenter defaultCenter] postNotificationName:ReuploadMediaFileNotification object:self.upload];
    [self didTapBackButton:sender];
}


#pragma mark - Delegates -

#pragma mark - UIWebViewDelegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self showLoadingView:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self showLoadingView:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self showLoadingView:NO];
    
    DDLogSupport(@"Error loading document: %@",error);

    [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                message:[error localizedDescription]
                            buttonTitle:nil
                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                             completion:nil];
}

@end
