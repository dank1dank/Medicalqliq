//
//  BaseAttachmentViewController.h
//  qliq
//
//  Created by Valeriy Lider on 24.12.14.
//
//

#import <UIKit/UIKit.h>
#import "MediaFileUpload.h"

typedef NS_ENUM(NSInteger, ViewMode) {
    ViewModeForMediaTab = 0,
    ViewModeForGetAttachment = 1,
    ViewModeForConversation,
    ViewModeForPresentAttachment
};

@class MediaFile;

@interface BaseAttachmentViewController : UIViewController

@property (nonatomic, strong) UIDocumentInteractionController *docInteractionController;

//Data
@property (nonatomic, assign) ViewMode viewMode;
@property (nonatomic, assign) BOOL isPopupOpen;
@property (nonatomic, assign) BOOL shouldShowDeleteButton;
@property (nonatomic, assign) BOOL shouldDismissController;

@property (nonatomic, strong) MediaFile *mediaFile;
@property (nonatomic, strong) MediaFileUpload *upload;

- (void)openExternalWithUrl:(NSURL *)fileURL;

// Common methods
- (void)shareFile:(id)item;
- (void)shareFile;
- (void)removeMediaFileAndAttachment;
- (void)createConversationWithAttachment;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle completion:(void (^ __nullable)(void))completion;
- (BOOL)checkMediaFile:(MediaFile *)mediaFile;

// Implement this in subclass, filePath is the file to display
- (void)setMediaFilePath:(NSString *)filePath;

// MediaFile Upload methods
- (void) attemptToOpen:(QxMediaFile *)mediaFile;

- (void) cofigureButton:(UIButton*)button withColor:(UIColor*)color withBackgroundColor:(BOOL)needBackground;

@end
