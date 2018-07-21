//
//  ImageView.m
//  qliq
//
//  Created by Aleksey Garbarev on 25.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageAttachmentViewController.h"
#import "UIImageViewHelper.h"
#import "MediaFileDBService.h"

#import "ConversationViewController.h"
#import "MessageAttachment.h"

#import "MediaFileUploadDBService.h"
#import "UploadDetailView.h"

#define kValueDefaultDistance 20.f
#define kBlueColor RGBa(0, 120, 174, 1)

@interface ImageAttachmentViewController() <UIScrollViewDelegate>

/**
 IBOutlet
 */
@property (nonatomic, weak) IBOutlet UIButton *backButton;
@property (nonatomic, weak) IBOutlet UIButton *removeButton;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *uploadAgainButton;

/**
 UI
 */
@property (nonatomic, strong) UIScrollView * scrollView;
@property (nonatomic, strong) UIImageView * imageView;

@property (weak, nonatomic) IBOutlet UIView *detailView;
@property (weak, nonatomic) IBOutlet UIView *navigationView;

//Conctraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *detailViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *removeButtonXCenterConstraint;

/**
 Data
 */
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) UploadDetailView *uploadDetailView;

@end

@implementation ImageAttachmentViewController


- (void)dealloc {
    self.backButton = nil;
    self.removeButton = nil;
    self.shareButton = nil;
    self.uploadAgainButton = nil;
    self.scrollView = nil;
    self.imageView = nil;
    self.detailView = nil;
    self.navigationView = nil;
    self.fileURL = nil;
    self.uploadDetailView = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Buttons
    {
        self.removeButton.hidden = self.shouldShowDeleteButton ? NO : YES;
    }
    
    //UIScroll
    {
        self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        [self.scrollView setHeight:self.scrollView.frame.size.height - self.navigationView.frame.size.height - 20.f - 10.f];
        [self.scrollView setY:self.scrollView.frame.origin.y + self.navigationView.frame.size.height + 20.f + 10.f];
        self.scrollView.minimumZoomScale    = 1.0;
        self.scrollView.maximumZoomScale    = 5.0;
        self.scrollView.delegate            = self;
        self.scrollView.bounces             = NO;
        self.scrollView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.scrollView.bouncesZoom         = YES;
        self.scrollView.backgroundColor     =  self.upload ? [UIColor whiteColor] : [UIColor blackColor];
        self.scrollView.autoresizesSubviews = YES;
        self.scrollView.zoomScale           = 1;
        [self.view addSubview:self.scrollView];
    }
    
    //ImageView
    {
        self.imageView = [[UIImageView alloc] initWithFrame:self.scrollView.bounds];
        self.imageView.contentMode      = UIViewContentModeScaleAspectFit;
        self.imageView.center           = self.scrollView.center;
        self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.imageView.frame            = self.scrollView.bounds;
        [self.scrollView addSubview:self.imageView];

        self.scrollView.contentSize = self.imageView.bounds.size;
    }

    //Gesture
    {
        UITapGestureRecognizer *tapViewRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapScroll:)];
        [self.scrollView addGestureRecognizer:tapViewRecognizer];
    }
    
    //Navigation View
    [self.view sendSubviewToBack:self.scrollView];
    self.view.backgroundColor = self.upload ? [UIColor whiteColor] : [UIColor blackColor];
    self.navigationView.backgroundColor = self.upload ? [UIColor whiteColor] : [UIColor blackColor];

    [self cofigureButton:self.shareButton withColor:[UIColor whiteColor] withBackgroundColor:YES];
    [self cofigureButton:self.backButton withColor:[UIColor whiteColor] withBackgroundColor:YES];
    [self cofigureButton:self.removeButton withColor:[UIColor whiteColor] withBackgroundColor:YES];

    //Uploading Again button
    self.uploadAgainButton.hidden = ![self.upload isFailed];
    self.shareButton.hidden = !self.uploadAgainButton.hidden;
    if (!self.shareButton.hidden) {
        self.shareButton.hidden = self.viewMode == ViewModeForPresentAttachment;
    }
    
    if (!self.uploadAgainButton.hidden) {
        //Configure uploadAgainButton
        [self.uploadAgainButton setTitle:QliqLocalizedString(@"2463-TitleUploadAgain") forState:UIControlStateNormal];
        [self.uploadAgainButton setTitleColor:kBlueColor forState:UIControlStateNormal];
        self.uploadAgainButton.clipsToBounds = YES;
        self.uploadAgainButton.layer.masksToBounds = YES;
        self.uploadAgainButton.layer.cornerRadius = 12.f;
        [[self.uploadAgainButton layer] setBorderWidth:1.5f];
        [[self.uploadAgainButton layer] setBorderColor:kBlueColor.CGColor];

        //Confogure center position remove button
        self.removeButtonXCenterConstraint.constant = self.removeButtonXCenterConstraint.constant - (2*kValueDefaultDistance - self.uploadAgainButton.frame.size.width - self.removeButton.frame.size.width)/4;
    }
    else {
        self.removeButtonXCenterConstraint.constant = 0.f;
    }
    
    if ([self isAllowLoadingProgress])
    {
        if (self.mediaFile) {
            [self.mediaFile decryptAsyncCompletitionBlock:^{

                if ([self checkMediaFile:self.mediaFile])
                    [self setMediaFilePath:self.mediaFile.decryptedPath];
            }];
        }
        else if  (self.upload) {
            [self configureUploadDetailView];
            [self attemptToOpen:self.upload.mediaFile];
        }
    }
    else
    {
        if (self.mediaFile) {
            [self.mediaFile decrypt];
            if ([self checkMediaFile:self.mediaFile])
            {
                [self setMediaFilePath:self.mediaFile.decryptedPath];
            }
            self.detailView.hidden = YES;
            self.detailViewHeightConstraint.constant = 0.f;
        }
        else if (self.upload) {
            [self configureUploadDetailView];
            [self attemptToOpen:self.upload.mediaFile];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark - Private -

- (BOOL)isAllowLoadingProgress {
    return NO;
}

- (void)configureUploadDetailView {

    self.detailView.hidden = NO;

    self.uploadDetailView = [[UploadDetailView alloc] init];
    self.uploadDetailView.upload = self.upload;
    [self.uploadDetailView loadUploadEventsForUploadFile:self.upload];
    //Configure constraints
    self.detailViewHeightConstraint.constant = self.uploadDetailView.frame.size.height;

    self.uploadDetailView.upload = self.upload;
    [self.detailView addSubview:self.uploadDetailView];
    [self.detailView setFrame:self.uploadDetailView.bounds];
    [self.view layoutIfNeeded];
}

#pragma mark * Set...

- (void)setMediaFilePath:(NSString *)_filePath
{
    UIImage * image = [UIImage imageWithContentsOfFile:_filePath];
//    UIImage * image = [UIImage imageNamed:_filePath];
    self.imageView.image = image;
    image = nil;
}

#pragma mark * Get...

- (void)getUrlFile
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        self.fileURL = [[NSURL alloc] initFileURLWithPath:self.mediaFile.decryptedPath];
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:self.fileURL];
    });
}

#pragma mark - Actions -

#pragma mark * IBAction

- (IBAction)didTapBackButton:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)didTapRemoveButton:(id)sender
{
    [self removeMediaFileAndAttachment];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)didTapShareButton:(id)sender
{
   [self shareFile];
}

- (IBAction)didTapUploadAgainButton:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:ReuploadMediaFileNotification object:self.upload];
    [self didTapBackButton:sender];
}
#pragma mark * Gesture Action

- (void)didTapScroll:(UITapGestureRecognizer *)sender
{
    self.scrollView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.5f animations:^{
        
        CGFloat buttonAlpha = (0.f == self.backButton.alpha ? 1.f : 0.f);
        self.backButton.alpha = buttonAlpha;
        self.removeButton.alpha = buttonAlpha;
        self.shareButton.alpha = buttonAlpha;
        if (!self.uploadAgainButton.hidden) {
            self.uploadAgainButton.alpha = buttonAlpha;
        }
    } completion:^(BOOL finished) {
        
        self.scrollView.userInteractionEnabled = YES;
    }];
}

#pragma mark - Delegates -

#pragma mark * UIScroll Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)_scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (self.scrollView.zoomScale <= 1)
        self.imageView.center = self.scrollView.center;
}

@end
