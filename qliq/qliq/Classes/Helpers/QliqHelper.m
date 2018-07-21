//
//  QliqHelper.m
//  qliq
//
//  Created by Valerii Lider on 27/11/15.
//
//

#import "QliqHelper.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "QliqAccess.h"
#import "QliqAvatar.h"
#import "DeviceInfo.h"

NSString *const kUDKeyShowSignUpButton = @"shouldShowSignUp";

@implementation QliqHelper

+ (QliqHelper *)sharedInstance
{
    static QliqHelper *instance = nil;
    if (instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [[QliqHelper alloc]init];
        });
    }
    return instance;
}

+ (NSString *)currentBuildVersion {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return version;
}

+ (NSString *)currentVersion {
    NSString *shortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *versionToDisplay = [NSString stringWithFormat:@"%@ (%@)",shortVersion,bundleVersion];
    return versionToDisplay;
}

+ (void)shouldShowSignUpButton:(BOOL)shouldShow {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:shouldShow forKey:kUDKeyShowSignUpButton];
}

+ (void)getPickerForMode:(PickerMode)mode forViewController:(id)viewController returnPicker:(ReturnPickerBlock)returnPickerBlock {
    
    switch (mode) {
        case PickerModePhoto:
        case PickerModeVideo:
        case PickerModePhotoAndVideo: {
            if (returnPickerBlock) {
                BOOL cameraAvialable = [DeviceInfo sharedInfo].isSimulator ? YES : [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
                
                if (cameraAvialable) {
                    [QliqAccess hasCameraAccess:^(BOOL granted) {
                        if (granted) {
                            if (mode == PickerModeVideo)
                            {
                                [[QliqAvatar sharedInstance] chooseVideoQualityInView:appDelegate.window withCompletitionBlock:^(VideoQuality quality) {
                                    UIImagePickerController *picker = [QliqHelper pickerForMode:mode forViewController:viewController];
                                    [[QliqAvatar sharedInstance] setVideoQuality:quality forImagePicker:picker];
                                    returnPickerBlock(picker, NULL);
                                }];
                            } else {
                                UIImagePickerController *picker = [QliqHelper pickerForMode:mode forViewController:viewController];
                                returnPickerBlock(picker, NULL);
                            }
                        }
                    }];
                }
                else {
                    returnPickerBlock (nil, [self errorPickerForMode:mode]);
                }
            }
            break;
        }
        case PickerModeLibrary: {
            if (returnPickerBlock) {
                if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                    [QliqAccess hasPhotoLibraryAccess:^(BOOL granted) {
                        if (granted) {
                            returnPickerBlock ([QliqHelper pickerForMode:mode forViewController:viewController], NULL);
                        }
                    }];
                    
                } else {
                    returnPickerBlock (nil, [self errorPickerForMode:mode]);
                }
            }
            break;
        }
        default:
            if (returnPickerBlock) {
                returnPickerBlock (nil, [self errorPickerForMode:mode]);
            }
            break;
    }
}

#pragma mark - Private

+ (UIImagePickerController *)pickerForMode:(PickerMode)mode forViewController:(id)viewController {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = viewController;
    picker.allowsEditing = NO;
    
    if ([DeviceInfo sharedInfo].isSimulator && mode == PickerModePhotoAndVideo) {
        mode = PickerModeLibrary;
    }
    switch (mode) {
        case PickerModePhoto: {
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
            picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
            break;
        }
        case PickerModeVideo: {
            [QliqAccess hasMicrophoneAccess:nil];
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
            picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
            [picker setVideoQuality:UIImagePickerControllerQualityTypeMedium];
            break;
        }
        case PickerModePhotoAndVideo: {
            [QliqAccess hasMicrophoneAccess:nil];
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *)kUTTypeImage, (NSString *)kUTTypeMovie, nil];
            picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
            [picker setVideoQuality: UIImagePickerControllerQualityTypeLow];
            break;
        }
        case PickerModeLibrary: {
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, (NSString *) kUTTypeMovie, (NSString *) kUTTypeVideo, nil];
            break;
        }
        default:
            break;
    }
    return picker;
}

+ (NSError *)errorPickerForMode:(PickerMode)mode {
    
    NSString *errorDescription = @"";
    
    switch (mode) {
        case PickerModePhoto:
        case PickerModeVideo:
        case PickerModePhotoAndVideo: {
            errorDescription = QliqLocalizedString(@"3045-CameraUnavailable");
            break;
        }
        case PickerModeLibrary: {
            errorDescription = QliqLocalizedString(@"3046-PhotoLibraryUnavailable");
            break;
        }
        default:
            break;
    }
    return [NSError errorWithCode:0 description:errorDescription];
}

@end
