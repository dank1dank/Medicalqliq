//
//  QliqSignHelper.m
//  qliq
//
//  Created by Valerii Lider on 11/28/16.
//
//

#import "QliqSignHelper.h"
#import "QliqSignViewController.h"
#import "SelectPDFViewController.h"
#import "MediaGridViewController.h"

#import "AlertController.h"

#import "MediaFile.h"
#import "MediaFileDBService.h"
#import "MediaFileService.h"
#import "ThumbnailService.h"
#import "UserSessionService.h"
#import "NotificationUtils.h"
#import "SelectContactsViewController.h"
#import "DocumentAttachmentViewController.h"
#import "MainViewController.h"
#import "MediaViewController.h"
#import "FaxViewController.h"

#import "UploadsMediaViewController.h"

#define kKeyFullName @"fullName"
#define kKeyFirstName @"firstName"
#define kKeyLastName @"lastName"
#define kKeyInitials @"initials"
#define kKeyProfession @"profession"
#define kKeyStatus @"status"
#define kKeyEmail @"email"
#define kKeyAvatarImg @"avatarImg"
#define kKeyKey @"key"
#define kKeyMe @"me"
#define kKeyOthers @"others"

#define kBlueColor RGBa(1, 106, 153, 1)

typedef NS_ENUM(NSUInteger, SavingType) {
    SavingTypeStraight,
    SavingTypeReplace,
    SavingTypeKeepBoth
};

@interface  QliqSignHelper() <UIPopoverPresentationControllerDelegate>
@property (nonatomic, assign) BOOL uploadToQliqSTOROption;
@property (nonatomic, strong) QliqAlertView *saveAlertView;

@end

@implementation QliqSignHelper

+ (UIViewController *)currentTopViewController
{
    UIViewController * controller = appDelegate.navigationController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    
    if ([controller isKindOfClass:[UINavigationController class]])
    {
        controller = ((UINavigationController *)controller).viewControllers.lastObject;
    }
    
    return controller;
}

+ (void)openPDFInMediaViewController:(NSString *)path iSaving:(BOOL)iSaving needReturnToFaxView:(BOOL)returnToFaxView needOpenQliqSTOR:(BOOL)needToOpenQliqSTOR
{
    MediaFile *pdf = [[MediaFileDBService sharedService] mediafileWithName:path];
    if(pdf)
    {
        VoidBlock openPDFBlock = ^{
            
            DocumentAttachmentViewController *mediaViewer =  [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([DocumentAttachmentViewController class])];
            mediaViewer.showForQliqSign = YES;
            [SVProgressHUD showWithStatus:@"Saving PDF"];
            mediaViewer.mediaFile               = pdf;
            mediaViewer.shouldShowDeleteButton  = YES;
            // If this preview for Fax,after preview will opened FaxViewController, need to send 'returnToFaxView' flag
            mediaViewer.returnToFaxView = returnToFaxView;
             // If this preview save to QliqSTOR, after preview will opened UploadsToQliqStor, need to send 'needToOpenQliqSTOR' flag
            mediaViewer.needToOpenQliqSTOR = needToOpenQliqSTOR;
            
            dispatch_async_main(^{
                if ([SVProgressHUD isVisible])
                    [SVProgressHUD dismiss];
            });
            if (!iSaving) {
                [appDelegate.navigationController dismissViewControllerAnimated:YES completion:nil];
            }
            [appDelegate.navigationController pushViewController:mediaViewer animated:YES];
        };
        
        if (appDelegate.navigationController.presentedViewController)
        {
            [appDelegate.navigationController dismissViewControllerAnimated:NO completion:^{
                openPDFBlock();
            }];
        }
        else
        {
            openPDFBlock();
        }
    }
    else
        DDLogError(@"<---- openPDFInMediaViewController: Should not happens! --->");
}

+ (void)openUploadsViewControllerWithMediaFile:(NSString *)path {

    MediaFile *pdf = [[MediaFileDBService sharedService] mediafileWithName:path];
    if (pdf) {

        VoidBlock openUploadView = ^{

            UploadsMediaViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:@"UploadsMediaViewController"];
            controller.uploadToEMR = NO;
            controller.uploadingMediaFile = pdf;
            [appDelegate.navigationController pushViewController:controller animated:YES];
        };

        if (appDelegate.navigationController.presentedViewController)
        {
            [appDelegate.navigationController dismissViewControllerAnimated:YES completion:^{
                openUploadView();
            }];
        }
        else
        {
            openUploadView();
        }
    }
    else {
        DDLogError(@"<---- openUploadsMediaViewController: Should not happens! --->");
    }
}

+ (void)openFaxViewControllerWithMediaFile:(NSString *)path {
    
    MediaFile *pdf = [[MediaFileDBService sharedService] mediafileWithName:path];
    if (pdf) {
        
        VoidBlock openUploadView = ^{
            
            //Returned new PDF file to FaxViewController
            FaxViewController *faxViewController = nil;
            UIViewController *currentViewController = [self currentTopViewController];
            if ([currentViewController isKindOfClass:[QliqSignViewController class]]) {
                [appDelegate.navigationController popViewControllerAnimated:NO];
                currentViewController = [self currentTopViewController];
                
                if ([currentViewController isKindOfClass:[SelectPDFViewController class]]) {
                    [appDelegate.navigationController popViewControllerAnimated:NO];
                    currentViewController = [self currentTopViewController];
                    
                    if ([currentViewController isKindOfClass:[FaxViewController class]]) {
                        faxViewController = (FaxViewController *)currentViewController;
                        faxViewController.mediaFile = pdf;
                    }
                }
            }
        };
        
        if (appDelegate.navigationController.presentedViewController) {
            
            [appDelegate.navigationController dismissViewControllerAnimated:YES completion:^{
                if ([[self currentTopViewController] isKindOfClass:[MediaGridViewController class]]) {
                    [appDelegate.navigationController popViewControllerAnimated:NO];
                }
                openUploadView();
            }];
        } else {
            openUploadView();
        }
    } else {
        DDLogError(@"<---- openUploadsMediaViewController: Should not happens! --->");
    }
}


#pragma mark - Call Back Blocks -

- (void)saveBlockImplementationForController:(UIViewController *)controller temporaryFilePath:(NSString *)temporaryFilePath existingFile:(BOOL)isExisting
{
    UIAlertController *saveAlert = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"3029-TitleSaveDocument") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [saveAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = QliqLocalizedString(@"2405-EnterFileName");
        textField.textAlignment = NSTextAlignmentCenter;
        textField.keyboardType = UIKeyboardTypeDefault;
        textField.text = [MediaFile generatePdfFilename];
    }];
    
    if (self.saveAlertView == nil) {
        self.saveAlertView = [[QliqAlertView alloc] initWithInverseColor:NO];
    }
    
    self.saveAlertView.useUploadOption = YES;
    self.saveAlertView.hideSwitch = self.returnToFaxView ? YES : NO;
    self.saveAlertView.fileName = [MediaFile generatePdfFilename];
    
    [self.saveAlertView setContainerViewWithImage:[UIImage imageNamed:@""]
                                        withTitle:QliqLocalizedString(@"3029-TitleSaveDocument")
                                         withText:nil
                                     withDelegate:nil
                                 useMotionEffects:YES];
    [self.saveAlertView setButtonTitles:[NSMutableArray arrayWithObjects:QliqLocalizedString(@"4-ButtonCancel"), QliqLocalizedString(@"44-ButtonSave"), nil]];
    
    __block __weak typeof(self) weakSelf = self;
    [weakSelf.saveAlertView setOnButtonTouchUpInside:^(QliqAlertView *alertView, int buttonIndex) {
        
        if (buttonIndex != 0)
        {
            weakSelf.uploadToQliqSTOROption = [alertView isQliqSTOROption];
            
            if ([alertView savingTextFiledFileName].length == 0 || ([alertView savingTextFiledFileName].length >= 1 && [[[alertView savingTextFiledFileName]  substringWithRange:NSMakeRange(0, 1)] isEqualToString:@" "]))
            {
                UIAlertController *stringAlert = [UIAlertController alertControllerWithTitle:QliqLocalizedString(@"1023-TextError")
                                                                                     message:QliqLocalizedString(@"3031-TextFileNameNotBeEmpty")
                                                                              preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:QliqLocalizedString(@"4-ButtonCancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [stringAlert dismissViewControllerAnimated:YES completion:nil];
                    performBlockInMainThreadSync(^{
                        [alertView show];
                    });
                }];
                
                [stringAlert addAction:cancel];
                
                if (alertView)
                {
                    [[QliqSignHelper currentTopViewController] presentViewController:stringAlert animated:YES completion:^{
                        if (!stringAlert.presentationController) {
                            performBlockInMainThreadSync(^{
                                [alertView show];
                            });
                        }
                    }];
                }
                else
                {
                    [[QliqSignHelper currentTopViewController] presentViewController:stringAlert animated:YES completion:nil];
                }
            }
            else {
                
                __block NSString *tempFilePath = temporaryFilePath;
                __block NSString *copyTemporaryFilePath = nil;
                __block NSString *fileName = [[alertView savingTextFiledFileName] stringByAppendingPathExtension:@"pdf"];
                __block NSString *newSavedPath = [NSString stringWithFormat:@"%@%@",kDecryptedDirectory, fileName];
                
                NSString *pdfDocumentsDirectory = [MediaFileService generateAbsoluteDirectoryPathFor:@"pdf" fileName:fileName];
                NSString *potentialyExistedFile = [pdfDocumentsDirectory stringByAppendingPathComponent:fileName];
                NSString *temporaryFileDirectory = [NSString stringWithFormat:@"%@/", [tempFilePath stringByDeletingLastPathComponent]];
                
                if ([newSavedPath isEqualToString:tempFilePath] && ![temporaryFileDirectory isEqualToString:kDecryptedDirectory])
                {
                    DDLogSupport(@"TemporaryFile and saving file has the same directory");
                    return;
                }

                BOOL (^saveMediaFileBlock)(SavingType) = ^(SavingType savingType){
                    
                    BOOL succes = YES;
                    
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSError *error = nil;
                    
                    if (savingType == SavingTypeReplace)
                    {
                        MediaFile *pdf = [[MediaFileDBService sharedService] mediafileWithName:potentialyExistedFile.lastPathComponent];
                        if(pdf)
                            [[MediaFileDBService sharedService] removeMediaFileAndAttachment:pdf];
                        else
                            DDLogError(@"<---- saveBlockImplementationForController: Should not happens! --->");
                        
                        if ([newSavedPath isEqualToString:tempFilePath])
                        {
                            copyTemporaryFilePath = [NSString stringWithFormat:@"%@", [tempFilePath stringByDeletingPathExtension]];
                            copyTemporaryFilePath = [[NSString stringWithFormat:@"%@*", copyTemporaryFilePath] stringByAppendingPathExtension:@"pdf"];
                            [fileManager copyItemAtPath:tempFilePath toPath:copyTemporaryFilePath error:&error];
                            
                            if (error)
                            {
                                DDLogError(@"///---- Error on copy file from: \n%@\n to %@ \n Error:\n %@", tempFilePath, copyTemporaryFilePath, [error localizedDescription]);
                                error = nil;
                            }
                            [fileManager removeItemAtPath:tempFilePath error:&error];
                            tempFilePath = copyTemporaryFilePath;
                        }
                        
                        [fileManager removeItemAtPath:potentialyExistedFile error:&error];
                        
                        if (error)
                        {
                            DDLogError(@"///---- Error on removing file from: \n%@\n Error:\n %@", potentialyExistedFile, [error localizedDescription]);
                            error = nil;
                        }
                    }
                    else if (savingType == SavingTypeKeepBoth)
                    {
                        NSString *nameFormat = [[fileName stringByDeletingPathExtension] stringByAppendingString:@"("];
                        NSInteger count = [[MediaFileDBService sharedService] countOfMediaFilesWithMimeTypes:[[MediaFileService getInstance] pdfMimeTypes] containsFormatInName:nameFormat];
                        fileName = [[NSString stringWithFormat:@"%@(%ld)",[fileName stringByDeletingPathExtension], ((long)count + 1)] stringByAppendingPathExtension:@"pdf"];
                        newSavedPath = [NSString stringWithFormat:@"%@%@",kDecryptedDirectory, fileName];
                        
                    }
                    
                    MediaFile *mediaFile = [[MediaFile alloc] init];
                    
                    //Replacing '/' symbols in file name to '_'
                    //Valerii Lider 02/21/18
                    if ([fileName containsString:@"/"]) {
                       NSString * replacingFileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                        newSavedPath = [NSString stringWithFormat:@"%@%@",kDecryptedDirectory, replacingFileName];
                    }
                    
                    mediaFile.fileName = fileName ? : @"testPDF.pdf";
                    mediaFile.decryptedPath = newSavedPath;
                    mediaFile.mimeType = @"pdf";
                    mediaFile.timestamp = [NSDate date].timeIntervalSince1970;
                    
                    //Clear decrypted temp path
                    succes = [fileManager moveItemAtPath:temporaryFilePath toPath:newSavedPath error:&error];

                    if (error)
                        DDLogError(@"///---- Error on removing file from: \n%@\n Error:\n %@", newSavedPath, [error localizedDescription]);
                    
                    if (copyTemporaryFilePath)
                    {
                        error = nil;
                        [fileManager removeItemAtPath:copyTemporaryFilePath error:&error];
                        if (error)
                        {
                            DDLogError(@"///---- Error on removing file from: \n%@\n Error:\n %@", copyTemporaryFilePath, [error localizedDescription]);
                            error = nil;
                        }
                    }
                    
                    if (succes)
                    {
                        //Request for thumbnail to cache it
                        [[ThumbnailService sharedService] thumbnailForMediaFile:mediaFile];
                        succes = [mediaFile encrypt];
                        if (succes)
                        {
                            succes = [mediaFile save];
                            if (succes)
                            {
                                // Open Preview for PDF file
                                [QliqSignHelper openPDFInMediaViewController:mediaFile.fileName iSaving:YES needReturnToFaxView:weakSelf.returnToFaxView needOpenQliqSTOR:weakSelf.uploadToQliqSTOROption];
                            
                                if (isExisting)
                                {
                                    if ([controller isKindOfClass:[QSPDFPreviewController  class]])
                                        [(QSPDFPreviewController *)controller doneSaving:mediaFile.fileName];
                                }
                                else
                                {
                                    if ([controller isKindOfClass:[QSPagesViewController class]])
                                        [(QSPagesViewController *)controller doneSaving:mediaFile.fileName];
                                }
                                //No need this code now, because app always open PDF preview
//                                if (weakSelf.uploadToQliqSTOROption && mediaFile != nil) {
//                                    if (weakSelf.returnToFaxView) {
//                                        [QliqSignHelper openFaxViewControllerWithMediaFile:mediaFile.fileName];
//                                    } else {
//                                        [QliqSignHelper openUploadsViewControllerWithMediaFile:mediaFile.fileName];
//                                    }
//                                }
//                                else {
//                                    if (weakSelf.returnToFaxView) {
//
//                                        [QliqSignHelper openFaxViewControllerWithMediaFile:mediaFile.fileName];
//                                    } else {
//                                        [QliqSignHelper openPDFInMediaViewController:mediaFile.fileName iSaving:YES needReturnToFaxView:weakSelf.returnToFaxView needOpenQliqSTOR:weakSelf.uploadToQliqSTOROption];
//                                    }
//                                }
                            }
                            else
                                DDLogError(@"///---- Saving failed for PDF with id: %ld decryptedPath: %@ encryptedPath: %@", (long)mediaFile.mediafileId, mediaFile.decryptedPath, mediaFile.encryptedPath);
                        }
                        else
                            DDLogError(@"///---- Error encryption failed for PDF with id: %ld decryptedPath: %@", (long)mediaFile.mediafileId, mediaFile.decryptedPath);
                    }
                    else
                    {
                        if (isExisting)
                        {
                            if ([controller isKindOfClass:[QSPDFPreviewController  class]])
                                [(QSPDFPreviewController *)controller doneSaving:nil];
                        }
                        else
                        {
                            if ([controller isKindOfClass:[QSPagesViewController class]])
                                [(QSPagesViewController *)controller doneSaving:nil];
                        }
                        
                        if (weakSelf.uploadToQliqSTOROption && mediaFile) {
                            if (weakSelf.returnToFaxView) {
                                [QliqSignHelper openFaxViewControllerWithMediaFile:mediaFile.fileName];
                            }
                            [QliqSignHelper openUploadsViewControllerWithMediaFile:mediaFile.fileName];
                        }
                        else {
                            [QliqSignHelper openPDFInMediaViewController:mediaFile.fileName iSaving:YES needReturnToFaxView:weakSelf.returnToFaxView needOpenQliqSTOR:weakSelf.uploadToQliqSTOROption];
                        }
                    }
                    
                    return succes;
                };
                
                NSFileManager *fileManager = [NSFileManager defaultManager];
                
                if ([fileManager fileExistsAtPath:potentialyExistedFile]) {
                    [AlertController showAlertWithTitle:QliqLocalizedString(@"1023-TextError")
                                                message:QliqLocalizedString(@"3032-TextFileIsAlreadyExists")
                                       withTitleButtons:@[QliqLocalizedString(@"3033-ButtonReplace"),QliqLocalizedString(@"2421-TitleKeepBoth")]
                                      cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel") completion:^(NSUInteger buttonIndex) {
                                          switch (buttonIndex) {
                                              case 0:{
                                                  saveMediaFileBlock(SavingTypeReplace);
                                              }
                                                  break;
                                              case 1:{
                                                  saveMediaFileBlock(SavingTypeKeepBoth);
                                              }
                                                  break;
                                              case 2:{
                                                  
                                                  if (isExisting) {
                                                      if ([controller isKindOfClass:[QSPDFPreviewController  class]])
                                                          [(QSPDFPreviewController *)controller doneSaving:nil];
                                                  } else {
                                                      if ([controller isKindOfClass:[QSPagesViewController class]])
                                                          [(QSPagesViewController *)controller doneSaving:nil];
                                                  }
                                              }
                                                  break;
                                                  
                                              default:
                                                  break;
                                          }
                                      }];
                } else {
                    saveMediaFileBlock(SavingTypeStraight);
                }
            }
        }
    }];
    
    performBlockInMainThreadSync(^{
        [self.saveAlertView show];
    });
}

- (BOOL)fillSignAuthorizationBlockImplementation {
    
    // Make this 1 when you are testing locally
#if 0
    BOOL isFillAndSignAuthorized = YES;
#else
    BOOL isFillAndSignAuthorized = [UserSessionService currentUserSession].userSettings.userFeatureInfo.isFillAndSignAvailable;
#endif
    
    if (!isFillAndSignAuthorized) {
        
        [AlertController showAlertWithTitle:QliqLocalizedString(@"2406-TitleNotActivated")
                                    message:QliqLocalizedString(@"2404-TextFillSignAuthorization")
                                buttonTitle:nil
                          cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                 completion:nil];
    }
    
    return isFillAndSignAuthorized;
}

+ (NSArray *)contactsForSigningWith:(NSArray *)selectedContacts {
    NSMutableArray *contactsArray = [NSMutableArray array];
    for (id item in selectedContacts)
    {
        NSDictionary *dict = [QliqSignHelper contactInfoDictionaryWithItem:item];
        if (dict)
            [contactsArray addObject:dict];
    }
    
    return [contactsArray copy];
}

+ (NSDictionary *)contactInfoDictionaryWithItem:(id)item
{
    UIImage *qliqAvatar = [[QliqAvatar sharedInstance] getAvatarForItem:item withTitle:nil];

    if ([item isKindOfClass:[Contact class]])
    {
        Contact *contact = (Contact *)item;
        NSString *initials = [NSString stringWithFormat:@"%@%@", [contact.firstName substringToIndex:1].uppercaseString, [contact.lastName substringToIndex:1].uppercaseString];
        NSDictionary *userDictionary = [NSDictionary dictionaryWithObjectsAndKeys:contact.firstName ? : @"", kKeyFirstName,
                                        contact.lastName ? : @"", kKeyLastName,
                                        initials ? : @"", kKeyInitials,
                                        contact.email ? : @"", kKeyEmail,
                                        qliqAvatar, kKeyAvatarImg,
                                        contact.qliqId ? : @"", kKeyKey,
                                        nil];
        return userDictionary;
    }
    else if ([item isKindOfClass:[QliqUser class]])
    {
        QliqUser *user = (QliqUser *)item;
        NSString *initials = [NSString stringWithFormat:@"%@%@", [user.firstName substringToIndex:1].uppercaseString, [user.lastName substringToIndex:1].uppercaseString];
        NSDictionary *userDictionary = [NSDictionary dictionaryWithObjectsAndKeys:user.firstName ? : @"", kKeyFirstName,
                                        user.lastName ? : @"", kKeyLastName,
                                        initials ? : @"", kKeyInitials,
                                        user.email ? : @"", kKeyEmail,
                                        qliqAvatar, kKeyAvatarImg,
                                        user.profession ? : @"", kKeyProfession,
                                        user.qliqId ? : @"", kKeyKey,
                                        [QliqUser presenceStatusToString:user.presenceStatus] ? : @"", kKeyStatus,
                                        nil];
        return userDictionary;
    }
    return nil;
}

- (void)setContactsBlockImplementationForController:(UIViewController *)controller callBackType:(QliqSignCallBackType)callBackType isExisting:(BOOL)isExisting;
{
    void (^setupDictionaryBlock)(NSArray *) = ^(NSArray * contacts){
        NSMutableDictionary *usersDictionary = [NSMutableDictionary dictionary];
        
        if (callBackType == QliqSignCallBackJustMe || callBackType == QliqSignCallBackMeAndOthers)
        {
            QliqUser *selfUser = [UserSessionService currentUserSession].user;
            NSDictionary *selfUserDictionary = [QliqSignHelper contactInfoDictionaryWithItem:selfUser];
            if (selfUserDictionary)
                [usersDictionary setObject:selfUserDictionary forKey:kKeyMe];
        }
        
        if (callBackType != QliqSignCallBackJustMe)
        {
            [usersDictionary setObject:[QliqSignHelper contactsForSigningWith:contacts] forKey:kKeyOthers];
        }
        
        if (isExisting)
        {
            if ([controller isKindOfClass:[QSPDFPreviewController  class]])
                [(QSPDFPreviewController *)controller setContacts:usersDictionary];
        }
        else
        {
            if ([controller isKindOfClass:[QSPagesViewController class]])
                [(QSPagesViewController *)controller setContacts:usersDictionary];
        }
    };
    
    if (callBackType != QliqSignCallBackJustMe)
    {
        SelectContactsViewController *selectContactsController = [[SelectContactsViewController alloc] init];
        selectContactsController = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([SelectContactsViewController class])];
        selectContactsController.typeController   = STForQliqSign;
        selectContactsController.selectParticipantsCallBack = ^(NSArray * selectedContacts, SelectContactsViewController *selectController){
            setupDictionaryBlock(selectedContacts);
        };
        
        selectContactsController.modalPresentationStyle = UIModalPresentationPopover;
        CGRect toolbarRect = CGRectMake(0, [QliqSignHelper currentTopViewController].view.height - 64.f, [QliqSignHelper currentTopViewController].view.width , 64.f);
        selectContactsController.popoverPresentationController.sourceRect = CGRectMake(toolbarRect.size.width - 10.f - 125.f,
                                                                                       toolbarRect.origin.y + 12.f,
                                                                                       125,
                                                                                       40);
        CGFloat height = [[UIScreen mainScreen] bounds].size.height - 128.f;
        CGFloat weight = [[UIScreen mainScreen] bounds].size.width - 60.f;
        selectContactsController.preferredContentSize = CGSizeMake(weight, height);
        selectContactsController.popoverPresentationController.sourceView = [QliqSignHelper currentTopViewController].view;
        selectContactsController.popoverPresentationController.delegate = (id<UIPopoverPresentationControllerDelegate>)self;
        [[QliqSignHelper currentTopViewController] presentViewController:selectContactsController animated:YES completion:nil];
    }
    else
    {
        setupDictionaryBlock(nil);
    }
}

#pragma mark - UIPopoverPresentation Delegate -

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

- (UIViewController *)presentationController:(UIPresentationController *)controller viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style {
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller.presentedViewController];
    return navController;
}


#pragma mark - QSEditingDone Delegate -

- (void)canceledEditing {
    DDLogSupport(@"Cancelled.....");
}

- (void) doneEditing:(NSString *)path  :(NSDictionary *)signedUser
{
    DDLogSupport(@"Document Path: %@", path);

    AppDelegate *appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
    [appDelegate.qliqSignObj qliqsignAddAuditLog:path :2 :[NSDate date] :[NSString stringWithFormat:@"Filled by %@ %@", [signedUser objectForKey:@"firstName"], [signedUser objectForKey:@"lastName"]]];
    [appDelegate.qliqSignObj qliqsignAddAuditLog:path :1 :[NSDate date] :[NSString stringWithFormat:@"Signed by %@ %@", [signedUser objectForKey:@"firstName"], [signedUser objectForKey:@"lastName"]]];

    if (self.uploadToQliqSTOROption) {
        if (self.returnToFaxView) {
            [QliqSignHelper openFaxViewControllerWithMediaFile:path];
        } else {
        [QliqSignHelper openUploadsViewControllerWithMediaFile:path];
        }
    } else {
        [QliqSignHelper openPDFInMediaViewController:path iSaving:NO needReturnToFaxView:self.returnToFaxView needOpenQliqSTOR:self.uploadToQliqSTOROption];
    }
}

@end
