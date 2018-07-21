//
//  QSImagePickerController.h
//  QliqSign
//
//  Created by macb on 9/21/16.
//  Copyright © 2016 macb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QSCaptureSession.h"
#import <MediaPlayer/MediaPlayer.h>

typedef NS_ENUM(NSUInteger, QSImagePickerControllerSourceType)
{
    QSImagePickerControllerSourceTypeCamera,
    QSImagePickerControllerSourceTypePhotoLibrary,
    QSImagePickerControllerSourceTypeQliqApp
};

@protocol QSImagePickerControllerDelegate <NSObject>
    
@required
- (void)imagePickerDidCancel;
- (void)imagePickerDidChooseImage:(UIImage *)path;
    
@end

@interface QSImagePickerController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    BOOL flashIsOn;
    BOOL imagePickerDismissed;
}

@property (nonatomic,assign) id<QSImagePickerControllerDelegate> delegate;

@property (strong, nonatomic) QSCaptureSession *captureManager;
@property (strong, nonatomic) UIToolbar *cameraToolbar;
@property (strong, nonatomic) UIBarButtonItem *flashButton;
@property (strong, nonatomic) UIBarButtonItem *pictureButton;
@property (strong, nonatomic) UIImageView *gridCameraView;
@property (strong, nonatomic) UIView *cameraPictureTakenFlash;

@property (strong, nonatomic) UIImage *existingImage;
    
@property (strong ,nonatomic) UIImagePickerController *invokeCamera;
    
@property QSImagePickerControllerSourceType sourceType;
    
@property (strong, nonatomic) MPVolumeView *volumeView;
    
@end
