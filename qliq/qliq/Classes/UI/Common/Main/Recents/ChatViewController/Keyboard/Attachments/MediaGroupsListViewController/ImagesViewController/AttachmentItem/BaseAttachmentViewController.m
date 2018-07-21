//
//  BaseAttachmentViewController.m
//  qliq
//
//  Created by Valeriy Lider on 24.12.14.
//
//

#import "BaseAttachmentViewController.h"

#import "MessageAttachment.h"
#import "MessageAttachmentDBService.h"
#import "MediaFileDBService.h"
#import "MediaFileService.h"
#import "ConversationViewController.h"
#import "QliqSignViewController.h"
#import "MediaGridViewController.h"

#import "QliqConnectModule.h"
#import "ChatMessageService.h"

#import "ChatMessage.h"
#import "QliqSignHelper.h"
#import <QliqSign/QSPDFPreviewController.h>

#import "SearchPatientsViewController.h"
#import "UploadsMediaViewController.h"
#import "MediaFileUploadDBService.h"
#import "QliqGroupDBService.h"

#import "AlertController.h"
#import "FaxViewController.h"

#define kUpdateUploadFiles @"UpdateUploadFiles"

@interface BaseAttachmentViewController () <QSImagePickerControllerDelegate, MediaGridViewControllerDelegate>

@property (nonatomic, assign) BOOL previousControlollerWithNavigationBar;
@property (nonatomic, assign) BOOL pdfPreview;
@property (strong ,nonatomic) QSPDFPreviewController *pdfPreviewController;
@property (strong, nonatomic) QSPagesViewController *pagesViewController;
@property (strong ,nonatomic) QSImagePickerController *imagePickerController;
@property (strong, nonatomic) QliqSignHelper *qliqSignHelper;
@property (strong, nonatomic) QSImagePickerController *imagePicker;

@end

@implementation BaseAttachmentViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isPopupOpen = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApplicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.previousControlollerWithNavigationBar = self.navigationController.navigationBar.hidden;
    
    [self.navigationController setNavigationBarHidden:YES];
    [self.navigationController.navigationBar setTranslucent:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:self.previousControlollerWithNavigationBar];
    [self.navigationController.navigationBar setTranslucent:self.previousControlollerWithNavigationBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.pdfPreviewController  = nil;
    self.qliqSignHelper        = nil;
    self.pagesViewController   = nil;
    self.imagePickerController = nil;
    self.viewMode              = nil;
    self.mediaFile             = nil;
    self.upload                = nil;
   
}

- (void) openExternalWithUrl:(NSURL *)fileURL {
    // We need to assign the UIDocumentInteractionController to an instance variable so ARC doesn't deallocate it before user finishes interaction.
    self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
//    [self.docInteractionController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    [self.docInteractionController presentOptionsMenuFromRect:CGRectZero inView:self.view animated:YES];
    self.isPopupOpen = YES;
}

- (void)onApplicationWillEnterForeground
{
    if(self.isPopupOpen) {
        [self.docInteractionController dismissMenuAnimated:YES];
        self.isPopupOpen = NO;
    }
}

#pragma mark - Public -

- (void)removeMediaFileAndAttachment
{
    if (self.mediaFile) {
        [[MediaFileDBService sharedService] removeMediaFileAndAttachment:self.mediaFile];
    }
    else if (self.upload) {
        [MediaFileUploadDBService removeUploadAndMediaFile:self.upload.mediaFile];
        [QxMediaFileManager remove:self.upload.mediaFile];
        //Need to post CN for updating upload files
        [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateUploadFiles object:self.upload.mediaFile];
    }
}

- (BOOL)checkMediaFile:(MediaFile *)mediaFile
{
    BOOL isOK = (!mediaFile || !mediaFile.decryptedPath) ? NO : YES;
    
    if (!isOK) {
        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                    message:QliqLocalizedString(@"1024-TextFileIncorrect")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                 completion:nil];
    }
    
    return isOK;
}

- (void) setMediaFilePath:(NSString *)filePath
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void) attemptToOpen:(QxMediaFile *)mediaFile
{
    if (mediaFile.isCanView) {
        // 1. File is ready to be open
        NSString *pathToOpen = mediaFile.filePathForView;
        [self setMediaFilePath:pathToOpen];
    } else if (mediaFile.isCanDecrypt) {
        // 2. File need to be decrypted and then can be open
        if ([QxMediaFileManager decrypt:mediaFile] == YES) {
            [self attemptToOpen:mediaFile];
        } else {
            [AlertController showAlertWithTitle:nil
                                        message:QliqLocalizedString(@"1095-TextFailedToDecryptFile")
                                    buttonTitle:nil
                              cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                     completion:nil];
        }
    } else if (mediaFile.isCanDownload) {
        // 3. No file on disk, first need to download
        [SVProgressHUD showWithStatus:@"Downloading..."];
        __weak typeof(self) weakSelf = self;
        [QxMediaFileManager download:mediaFile withCompletion:^(int mediaFileId, NSString *errorMessage) {
            // By the time file is download the view controller can be already destroyed
            // Check if weakSelf is still valid            
            if (weakSelf) {
                [SVProgressHUD dismiss];
                
                if (errorMessage.length > 0) {
                    
                    [AlertController showAlertWithTitle:nil
                                                message:errorMessage
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                             completion:nil];

                } else {
                    QxMediaFile *updatedMediaFile = [QxMediaFileDBService getWithId:mediaFileId];
                    [weakSelf attemptToOpen:updatedMediaFile];
                }
            }
        }];
    } else {
        DDLogSupport(@"Can't to open uploading media fileName - %@", mediaFile.fileName);
        
        [AlertController showAlertWithTitle:nil
                                    message:QliqLocalizedString(@"1024-TextFileIncorrect")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                 completion:nil];
        
    }
}

- (void) cofigureButton:(UIButton*)button withColor:(UIColor*)color withBackgroundColor:(BOOL)needBackground {
    
    color = self.upload ? RGBa(4.f, 121.f, 173.f, 1.f) : color;
    button.tintColor = color;
    button.layer.cornerRadius = button.bounds.size.height/2.f;
    button.layer.borderWidth = 1;
    needBackground = self.upload ? NO : needBackground;
    button.backgroundColor = needBackground ? RGBa(175.f, 175.f, 175.f, 0.3f) : [UIColor clearColor];
    button.layer.borderColor = [button.tintColor CGColor];
    button.clipsToBounds = YES;
}

#pragma mark * Actions

- (void)shareFile
{
    [self shareFile:nil];
}

- (void)shareFile:(id)item
{
    //Share option
    /*
     if(self.mediaFile.decryptedPath)
     {
     NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:self.mediaFile.decryptedPath];
     [self openExternalWithUrl:fileURL];
     }
     //*/
    
//    return;
    
    if (self.viewMode == ViewModeForGetAttachment) {
        
        MessageAttachment *attachment = [[ MessageAttachment alloc ] initWithMediaFile:self.mediaFile];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddAttachmentToMessage" object:attachment userInfo:nil];
        
        if (self.shouldDismissController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        BOOL canPrintURL = NO;
        
        if (self.mediaFile.decryptedPath)
            [UIPrintInteractionController canPrintURL:[[NSURL alloc] initFileURLWithPath:self.mediaFile.decryptedPath]];
        
        BOOL shouldAddPrintFeature = item ? YES : canPrintURL;
        BOOL isKiteworksIntegrated = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isKiteworksIntegrated;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        __weak BaseAttachmentViewController *weakself = self;
        
        NSString *createConversationMessage = self.viewMode == ViewModeForConversation ? QliqLocalizedString(@"1108-TextForward")
        : QliqLocalizedString(@"1109-TextAttachAndSendMessage");
        
        UIAlertAction *createConversationWithAttachment = [UIAlertAction actionWithTitle:createConversationMessage
                                                                                   style:UIAlertActionStyleDefault
                                                                                 handler:^(UIAlertAction *action) {
            
            __strong BaseAttachmentViewController *strongself = weakself;
            [strongself createConversationWithAttachment];
        }];
    
        UIAlertAction *uploadToEMR = [UIAlertAction actionWithTitle:QliqLocalizedString(@"1110-TextUploadToEMR")
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
            
            // Make this 1 when you are testing locally
#if 0
            BOOL isEMRIntegrated = YES;
#else
            BOOL isEMRIntegrated = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isEMRIntegated;
#endif
            if (isEMRIntegrated) {
                SearchPatientsViewController *searchPetientsController = [kMainStoryboard instantiateViewControllerWithIdentifier:@"SearchPatientsViewController"];
                searchPetientsController.mediaFile = self.mediaFile;
                [self.navigationController pushViewController:searchPetientsController animated:YES];
            } else {
                DDLogSupport(@"\n\nEMR Integration Not Activated...\n\n");
                
                [AlertController showAlertWithTitle:nil
                                            message:QliqLocalizedString(@"1111-TextEMRNotActivate")
                                        buttonTitle:QliqLocalizedString(@"1-ButtonOK")
                                  cancelButtonTitle:nil
                                         completion:nil];
            }
        }];

        UIAlertAction *uploadToQliqSTOR = [UIAlertAction actionWithTitle:QliqLocalizedString(@"1227-TextUploadToQliqStor")
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {

            BOOL isUploadQliqSTORIntegrated = [QliqGroupDBService hasAnyQliqStor];
            if (isUploadQliqSTORIntegrated) {
                if (self.mediaFile != nil) {

                    UploadsMediaViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:@"UploadsMediaViewController"];
                    controller.uploadToEMR = NO;
                    controller.uploadingMediaFile = self.mediaFile;
                    [self.navigationController pushViewController:controller animated:YES];
                } else {
                    DDLogSupport(@"\n\nMedia file is incorrect...\n\n");
                    [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                                message:QliqLocalizedString(@"1024-TextFileIncorrect")
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOk")
                                             completion:nil];
                }
            } else {
                DDLogSupport(@"Cannot show upload to qliqStor UI because there is no qliqStor in db");
                
                [AlertController showAlertWithTitle:nil
                                            message:QliqLocalizedString(@"3040-QliqSTORisNotActivated")
                                        buttonTitle:nil
                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                         completion:nil];
            }
        }];
        
        UIAlertAction *uploadToKiteworks = [UIAlertAction actionWithTitle:QliqLocalizedString(@"1222-TextUploadToKiteworks")
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      if (isKiteworksIntegrated) {
                                                                          DDLogSupport(@"\n\nKiteworks still not integrated...\n\n");
                                                                      } else {
                                                                          [AlertController showAlertWithTitle:nil
                                                                                                      message:QliqLocalizedString(@"1221-TextKiteworksConnectivityNotActivated")
                                                                                                  buttonTitle:nil
                                                                                            cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                                                                   completion:nil];
                                                                      }
                                                                  }];
        
        UIAlertAction *print = [UIAlertAction actionWithTitle:QliqLocalizedString(@"1112-TextPrint") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            if (canPrintURL && self.mediaFile.decryptedPath) {
                NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:self.mediaFile.decryptedPath];
                [UIPrintInteractionController sharedPrintController].printingItem = fileURL;
            }
            else
                [UIPrintInteractionController sharedPrintController].printFormatter = item;
            
            [[UIPrintInteractionController sharedPrintController] presentFromRect:CGRectZero inView:self.view animated:YES completionHandler:^(UIPrintInteractionController * _Nonnull printInteractionController, BOOL completed, NSError * _Nullable error) {
                
                if (error) {
                    
                    [AlertController showAlertWithTitle:nil
                                                message:error.localizedDescription
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                             completion:nil];
                }
            }];
        }];
        
        [alert addAction:createConversationWithAttachment];
        [alert addAction:uploadToEMR];
        [alert addAction:uploadToQliqSTOR];
        
        if (isKiteworksIntegrated)
            [alert addAction:uploadToKiteworks];
        if (shouldAddPrintFeature)
            [alert addAction:print];
       
        if ([[MediaFileService getInstance] isPDF:self.mediaFile])
        {
            __weak __block typeof(self) welf = self;
            UIAlertAction *qliqSign = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2400-TitleFillAndSign")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                welf.qliqSignHelper = nil;
                welf.qliqSignHelper = [[QliqSignHelper alloc] init];
                
                welf.pdfPreviewController = [[QSPDFPreviewController alloc] init];
                welf.pdfPreviewController.pdfEditingDoneDelegate = welf.qliqSignHelper;
                welf.pdfPreviewController.pdfFileName = self.mediaFile.decryptedPath;
                welf.pdfPreviewController.isExistingPDF = true;
                
                welf.pdfPreviewController.saveBlock = ^(NSString *tempFilePath){
                    [welf.qliqSignHelper saveBlockImplementationForController:welf.pdfPreviewController temporaryFilePath:tempFilePath existingFile:YES];
                };
                welf.pdfPreviewController.fillSignAuthorizationBlock = ^{
                    return (bool)[welf.qliqSignHelper fillSignAuthorizationBlockImplementation];
                };
                
                welf.pdfPreviewController.meandothersBlock = ^{
                    if ([welf.qliqSignHelper fillSignAuthorizationBlockImplementation]) {
                    [welf.qliqSignHelper setContactsBlockImplementationForController:welf.pdfPreviewController callBackType:QliqSignCallBackMeAndOthers isExisting:YES];
                    }
                };
                
                welf.pdfPreviewController.othersBlock = ^{
                    if ([welf.qliqSignHelper fillSignAuthorizationBlockImplementation]) {
                    [welf.qliqSignHelper setContactsBlockImplementationForController:welf.pdfPreviewController callBackType:QliqSignCallBackOthersOnly isExisting:YES];
                    }
                };
                
                welf.pdfPreviewController.justmeBlock = ^{
                    if ([welf.qliqSignHelper fillSignAuthorizationBlockImplementation]) {
                        [welf.qliqSignHelper setContactsBlockImplementationForController:welf.pdfPreviewController callBackType:QliqSignCallBackJustMe isExisting:YES];
                    }
                    
                };
                [[QliqSignHelper currentTopViewController] presentViewController:welf.pdfPreviewController animated:YES completion:nil];
            }];
            
            [alert addAction:qliqSign];
        
        UIAlertAction *sendFax = [UIAlertAction actionWithTitle:QliqLocalizedString(@"3060-SendFax")
                                                            style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                                                            
                                                            BOOL isFaxIntegrated = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isFAXIntegated;
                                                            
                                                            if (isFaxIntegrated) {
                                                                
                                                                FaxViewController *faxViewController =  [kMainStoryboard instantiateViewControllerWithIdentifier:@"FaxViewController"];
                                                                faxViewController.mediaFile = self.mediaFile;
                                                                [self.navigationController pushViewController:faxViewController animated:YES];
                                                            } else {
                                                                
                                                                DDLogSupport(@"\n\nFAX Integration Not Activated...\n\n");
                                                                [AlertController showAlertWithTitle:nil
                                                                                            message:QliqLocalizedString(@"3059-TextFAXNotActivate")
                                                                                        buttonTitle:nil
                                                                                  cancelButtonTitle:QliqLocalizedString(@"1-ButtonOK")
                                                                                         completion:nil];
                                                            }
                                                        }];
            [alert addAction:sendFax];
        } else {
        
            UIAlertAction *saveAsPDF = [UIAlertAction actionWithTitle:QliqLocalizedString(@"2423-TitleSaveAsPDF")
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                
                if (self.mediaFile.decryptedPath != nil) {
                    
                    QSImagePickerController *imagePicker = [[QSImagePickerController alloc] init];
                    [imagePicker setDelegate:self];
                    imagePicker.sourceType = QSImagePickerControllerSourceTypeQliqApp;
                    
                    UIImage *img =[UIImage imageWithContentsOfFile:self.mediaFile.decryptedPath];
                    if (img) {
                        
                        [imagePicker setExistingImage:img];
                        
                        QSNavigationController *navigationController = [[QSNavigationController alloc] initWithRootViewController:imagePicker];
                        [self presentViewController:navigationController animated:YES completion:nil];
                    }
                    else {
                        [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                                    message:QliqLocalizedString(@"1938-StatusErrorCannotFindAttachment")
                                                buttonTitle:nil
                                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                                 completion:nil];
                    }
                } else {
                    [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                                message:QliqLocalizedString(@"1938-StatusErrorCannotFindAttachment")
                                            buttonTitle:nil
                                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                             completion:nil];
                }
            }];
            
            [alert addAction:saveAsPDF];
        }
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:QliqLocalizedString(@"4-ButtonCancel") style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        
        alert.preferredContentSize = CGSizeMake(450, 350);
        alert.popoverPresentationController.sourceView =self.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds)+50, 0, 0);
        alert.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)imagePickerDidCancel {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerDidChooseImage:(UIImage *)path {
    
    if(self.pagesViewController == nil || !self.pagesViewController.isAvailableDocument)
    {
        self.qliqSignHelper = nil;
        self.qliqSignHelper = [[QliqSignHelper alloc] init];
        self.pagesViewController = [[QSPagesViewController alloc] init];
        self.pagesViewController.pdfEditingDoneDelegate = self.qliqSignHelper;
        [self.pagesViewController.images addObject:path];
        
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
            [welf openQliqGallery];

        };
        
        [[QliqSignHelper currentTopViewController] presentViewController:self.pagesViewController animated:YES completion:nil];
    }
    else
    {
        [self.pagesViewController.images addObject:path];
        [self.pagesViewController updateView];
        [[QliqSignHelper currentTopViewController] dismissViewControllerAnimated:YES completion:NULL];
    }
}

#pragma mark - Private -
- (void)openQliqGallery {
    
    MediaGridViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([MediaGridViewController class])];
    controller.delegate = self;
    controller.viewOptions = [[NSDictionary alloc] initWithObjectsAndKeys:@"Images", @"kViewerTitle", nil];
    controller.viewArhive = YES;
    
    QSNavigationController *navigationController = [[QSNavigationController alloc] initWithRootViewController:controller];
    [[QliqSignHelper currentTopViewController] presentViewController:navigationController animated:YES completion:NULL];

}

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

- (void)createConversationWithAttachment
{
    MessageAttachment *attachment = [[ MessageAttachment alloc ] initWithMediaFile:self.mediaFile];
    
    ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
    controller.isNewConversation = YES;
    controller.attachment = attachment;
    
    [self.navigationController pushViewController:controller animated:YES];
}



@end
