//
//  ImageCaptureController.h
//  qliqConnect
//
//  Created by Paul Bar on 12/16/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ImageCaptureControllerDelegate <NSObject>

-(void) presentImageCaptureController:(UIViewController *)controller;
-(void) imageCaptured:(UIImage*)image withController:(UIViewController*)contorller;
-(void) imageCaptureControllerCanceled:(UIViewController*)controller;
@end

@interface ImageCaptureController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    UIImagePickerController *imagePicker;
}

@property (nonatomic, assign) UIViewController<ImageCaptureControllerDelegate>* delegate;

-(void) captureImage;

@end
