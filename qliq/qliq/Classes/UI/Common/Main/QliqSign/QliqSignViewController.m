//
//  QliqSignViewController.m
//  qliq
//
//  Created by Valerii Lider on 11/7/16.
//
//

#import "QliqSignViewController.h"

#import <QliqSign/QSImagePickerController.h>
#import <QliqSign/QSPagesViewController.h>

#import "MediaFile.h"
#import "MediaGridViewController.h"
#import "ThumbnailService.h"
#import "QliqSignHelper.h"

#import "QliqUserDBService.h"

#import "SelectContactsViewController.h"
#import "SelectPDFViewController.h"

#define kValueButtonCornerRadius    22.5
#define kValueButtonBorderWidth     1.f
#define kButtonBorderColor                [kColorDarkBlue CGColor]

#define kKeyFullName @"fullName"
#define kKeyEmail @"email"
#define kKeyUniqueId @"uniqueId"
#define kKeyMe @"me"
#define kKeyContacts @"contacts"

@interface QliqSignViewController () <UIImagePickerControllerDelegate, QSImagePickerControllerDelegate, SelectContactsViewControllerDelegate, MediaGridViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *fromCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *fromGalleryButton;
@property (weak, nonatomic) IBOutlet UIButton *fromExistingPictureButton;
@property (weak, nonatomic) IBOutlet UIButton *fromExistingDocumentButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) SelectContactsViewController *selectContactsController;

@property (strong, nonatomic) QSPagesViewController *pagesViewController;
@property (strong ,nonatomic) QSPDFPreviewController *pdfPreviewController;
@property (strong, nonatomic) QliqSignHelper *qliqSignHelper;
@property (strong, nonatomic) QSImagePickerController *imagePicker;


//Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topFromExistingDocumentButtonConstraint;

@end
@implementation QliqSignViewController

#pragma mark - Life Cycle -

- (void)dealloc {
    self.pagesViewController = nil;
    self.pdfPreviewController = nil;
    self.selectContactsController = nil;
    self.qliqSignHelper = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.fromCameraButton setTitle:QliqLocalizedString(@"2401-TitleFromCamera") forState:UIControlStateNormal];
    self.fromCameraButton.layer.cornerRadius = kValueButtonCornerRadius;
    self.fromCameraButton.layer.borderWidth = kValueButtonBorderWidth;
    self.fromCameraButton.layer.borderColor = kButtonBorderColor;
    
    [self.fromGalleryButton setTitle:QliqLocalizedString(@"2402-TitleFromGallery") forState:UIControlStateNormal];
    self.fromGalleryButton.layer.cornerRadius = kValueButtonCornerRadius;
    self.fromGalleryButton.layer.borderWidth = kValueButtonBorderWidth;
    self.fromGalleryButton.layer.borderColor = kButtonBorderColor;
    
    /*
    [self.fromExistingPictureButton setTitle:QliqLocalizedString(@"2422-ButtonFromExistingPicture") forState:UIControlStateNormal];
    self.fromExistingPictureButton.layer.cornerRadius = kValueButtonCornerRadius;
    self.fromExistingPictureButton.layer.borderWidth = kValueButtonBorderWidth;
    self.fromExistingPictureButton.layer.borderColor = kButtonBorderColor;
    */
    
    [self.fromExistingDocumentButton setTitle:QliqLocalizedString(@"2407-ButtonFromExistingDocument") forState:UIControlStateNormal];
    self.fromExistingDocumentButton.layer.cornerRadius = kValueButtonCornerRadius;
    self.fromExistingDocumentButton.layer.borderWidth = kValueButtonBorderWidth;
    self.fromExistingDocumentButton.layer.borderColor = kButtonBorderColor;
    
    self.fromExistingPictureButton.hidden = YES;
    self.topFromExistingDocumentButtonConstraint.constant = 22.f;
    
    self.titleLabel.text = QliqLocalizedString(@"2403-TitleGetPicture");
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)openQliqGallery {
    
    MediaGridViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MediaGridViewController class])];
    controller.delegate = self;
    controller.viewOptions = [[NSDictionary alloc] initWithObjectsAndKeys:@"Images", @"kViewerTitle", nil];
    controller.viewArhive = YES;

    QSNavigationController *navigationController = [[QSNavigationController alloc] initWithRootViewController:controller];
    [[QliqSignHelper currentTopViewController] presentViewController:navigationController animated:YES completion:NULL];
}

#pragma mark - Actions -

- (IBAction)cameraAction:(id)sender {
    
    [QliqAccess hasCameraAccess:^(BOOL granted) {
        if (granted)
        {
            QSImagePickerController *imagePicker = [[QSImagePickerController alloc] init];
            [imagePicker setDelegate:self];
            [imagePicker setSourceType:QSImagePickerControllerSourceTypeCamera];

            QSNavigationController *navigationController = [[QSNavigationController alloc] initWithRootViewController:imagePicker];
            [self presentViewController:navigationController animated:YES completion:nil];
        }
    }];
}

- (IBAction)pickerAction:(id)sender {
    
    [QliqAccess hasPhotoLibraryAccess:^(BOOL granted) {
        [self openQliqGallery];
    }];
}

- (IBAction)loadExistingPicture:(id)sender
{
    
}

- (IBAction)loadExistingDocument:(id)sender
{
    __weak __block typeof(self) welf = self;
    SelectPDFViewController *selectPDFViewController = [kMainStoryboard instantiateViewControllerWithIdentifier:@"SelectPDFViewController"];
    selectPDFViewController.selectPDFCallBack = ^(MediaFile *pdf){
        if([pdf decrypt]){
            welf.qliqSignHelper = nil;
            welf.qliqSignHelper = [[QliqSignHelper alloc] init];
            welf.qliqSignHelper.returnToFaxView = self.returnToFaxView;
            
            welf.pdfPreviewController = [[QSPDFPreviewController alloc] init];
            welf.pdfPreviewController.pdfEditingDoneDelegate = welf.qliqSignHelper;
            welf.pdfPreviewController.pdfFileName = pdf.decryptedPath;
            
            welf.pdfPreviewController.saveBlock = ^(NSString *tempFilePath){
                [welf.qliqSignHelper saveBlockImplementationForController:welf.pdfPreviewController temporaryFilePath:tempFilePath existingFile:YES];
            };
            welf.pdfPreviewController.fillSignAuthorizationBlock = ^{
                return (bool)[welf.qliqSignHelper fillSignAuthorizationBlockImplementation];
            };
            
            welf.pdfPreviewController.meandothersBlock = ^{
                [welf.qliqSignHelper setContactsBlockImplementationForController:welf.pdfPreviewController callBackType:QliqSignCallBackMeAndOthers isExisting:YES];
            };
            
            welf.pdfPreviewController.othersBlock = ^{
                [welf.qliqSignHelper setContactsBlockImplementationForController:welf.pdfPreviewController callBackType:QliqSignCallBackOthersOnly isExisting:YES];
            };
            
            welf.pdfPreviewController.justmeBlock = ^{
                [welf.qliqSignHelper setContactsBlockImplementationForController:welf.pdfPreviewController callBackType:QliqSignCallBackJustMe isExisting:YES];
            };
            [[QliqSignHelper currentTopViewController] presentViewController:welf.pdfPreviewController animated:YES completion:nil];
        }
        else
        {
            UIAlertController *warningAlert = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"1072-TextWarning")
                                                                                  message:@"The file could not be read"
                                                                           preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:QliqLocalizedString(@"4-ButtonCancel")
                                                             style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * _Nonnull action) {
                [warningAlert dismissViewControllerAnimated:YES completion:^{
                    [[QliqSignHelper currentTopViewController] dismissViewControllerAnimated:YES completion:nil];
                }];
            }];
            [warningAlert addAction:cancel];
            [[QliqSignHelper currentTopViewController] presentViewController:warningAlert animated:YES completion:nil];
        }
    };
    
    [self.navigationController pushViewController:selectPDFViewController animated:YES];
}

- (IBAction)onBackAction:(id)sender
{
    DDLogSupport(@"Back from QliqSignViewController");
    if (self.navigationController.presentingViewController && [[self.navigationController viewControllers].firstObject isEqual:self]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Delegate Methods -

#pragma mark - MediaGridViewController delegate

- (void)mediaGridViewController:(MediaGridViewController*)controller didSelectMediaFile:(MediaFile *)mediaFile
{
    [mediaFile decrypt];

    self.imagePicker = [[QSImagePickerController alloc] init];
    [self.imagePicker setDelegate:self];
    
    self.imagePicker.sourceType = QSImagePickerControllerSourceTypeQliqApp;
    
    UIImage *img =[UIImage imageWithContentsOfFile:mediaFile.decryptedPath];
    if (img) {
        
        [self.imagePicker setExistingImage:img];
        
        __weak __block typeof(self) welf = self;
        dispatch_async_main(^{

            QSNavigationController *navigationController = [[QSNavigationController alloc] initWithRootViewController:welf.imagePicker];
            [[QliqSignHelper currentTopViewController] presentViewController:navigationController animated:YES completion:NULL];
        });
    }
}

#pragma mark QSImagePicker delegate
- (void) imagePickerDidCancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) imagePickerDidChooseImage:(UIImage *)image
{
    if(self.pagesViewController == nil || !self.pagesViewController.isAvailableDocument)
    {
        self.qliqSignHelper = nil;
        self.qliqSignHelper = [[QliqSignHelper alloc] init];
        self.qliqSignHelper.returnToFaxView = self.returnToFaxView;
        self.pagesViewController = [[QSPagesViewController alloc] init];
        self.pagesViewController.pdfEditingDoneDelegate = self.qliqSignHelper;
        [self.pagesViewController.images addObject:image];
        
        __weak __block typeof(self) welf = self;
        self.pagesViewController.saveBlock = ^(NSString *temporaryFilePath) {
            [welf.qliqSignHelper saveBlockImplementationForController:welf.pagesViewController temporaryFilePath:temporaryFilePath existingFile:NO];
        };
        
        self.pagesViewController.fillSignAuthorizationBlock = ^{
            return (bool)[welf.qliqSignHelper fillSignAuthorizationBlockImplementation];
        };
        
        welf.pagesViewController.meandothersBlock = ^{
            [welf.qliqSignHelper setContactsBlockImplementationForController:welf.pagesViewController callBackType:QliqSignCallBackMeAndOthers isExisting:NO];
        };
        
        welf.pagesViewController.othersBlock = ^{
            [welf.qliqSignHelper setContactsBlockImplementationForController:welf.pagesViewController callBackType:QliqSignCallBackOthersOnly isExisting:NO];
        };
        
        welf.pagesViewController.justmeBlock = ^{
            [welf.qliqSignHelper setContactsBlockImplementationForController:welf.pagesViewController callBackType:QliqSignCallBackJustMe isExisting:NO];
        };
        welf.pagesViewController.addPageFromGallery = ^{
            [[QliqSignHelper currentTopViewController] dismissViewControllerAnimated:YES completion:NULL];
        };

        [[QliqSignHelper currentTopViewController] presentViewController:self.pagesViewController animated:YES completion:nil];
    }
    else
    {
       
        [self.pagesViewController.images addObject:image];
        [self.pagesViewController updateView];
        [[QliqSignHelper currentTopViewController] presentViewController:self.pagesViewController animated:YES completion:nil];
    }
}

@end
