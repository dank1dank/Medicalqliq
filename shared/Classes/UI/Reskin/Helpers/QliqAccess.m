//
//  QliqAccess.m
//  qliq
//
//  Created by Valerii Lider on 30/07/15.
//
//

#import "QliqAccess.h"

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "AlertController.h"

@implementation QliqAccess

+ (QliqAccess *)sharedInstance
{
    static QliqAccess *instance = nil;
    if (instance == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [[QliqAccess alloc]init];
        });
    }
    return instance;
}

#pragma mark - Public

+ (void)hasMicrophoneAccess:(AccessBlock)accessBlock {
    AccessBlock localBlock = ^(BOOL granted) {
        if(granted)
            DDLogSupport(@"Granted microfone access");
        else
        {
            DDLogSupport(@"Not granted microfone access");
            dispatch_async_main(^{
                [AlertController showAlertWithTitle:NSLocalizedString(@"1157-TextMicrophoneAccessDenied", nil)
                                            message:NSLocalizedString(@"1158-TextYouMustAllowMicrophoneAccessInSettings", nil)
                                        buttonTitle:NSLocalizedString(@"33-ButtonOpenSettings", nil)
                                  cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                         completion:^(NSUInteger buttonIndex) {
                                             if (buttonIndex == 0) {
                                                 NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                 [[UIApplication sharedApplication] openURL:url];
                                             }
                                         }];
            });
        }
        
        if (accessBlock)
            accessBlock(granted);
    };
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        
        dispatch_async_main(^{
            localBlock(granted);
        });
    }];
}

+ (void)hasCameraAccess:(AccessBlock)accessBlock {
    
    AccessBlock localBlock = ^(BOOL granted) {
        if(granted)
            DDLogSupport(@"Granted camera access");
        else
        {
            DDLogSupport(@"Not granted camera access");
            dispatch_async_main(^{
                [AlertController showAlertWithTitle:NSLocalizedString(@"1160-TextCameraAccessDenied", nil)
                                            message:NSLocalizedString(@"1161-TextYouMustAllowCameraaccessInSettings", nil)
                                        buttonTitle:NSLocalizedString(@"33-ButtonOpenSettings", nil)
                                  cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                         completion:^(NSUInteger buttonIndex) {
                                             if (buttonIndex == 0) {
                                                 NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                 [[UIApplication sharedApplication] openURL:url];
                                             }
                                         }];
            });
        }
        accessBlock(granted);
    };

    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(status == AVAuthorizationStatusAuthorized) {
        localBlock(YES);
    } else if(status == AVAuthorizationStatusDenied){
        localBlock(NO);
    } else if(status == AVAuthorizationStatusRestricted){
        localBlock(NO);
    } else if(status == AVAuthorizationStatusNotDetermined){
        // not determined
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async_main(^{
                localBlock(granted);
            });
        }];
    }
}

+ (void)hasPhotoLibraryAccess:(AccessBlock)accessBlock {
    
    AccessBlock localBlock = ^(BOOL granted) {
        if(granted)
            DDLogSupport(@"Granted PhotoLibrary access");
        else
        {
            DDLogSupport(@"Not granted PhotoLibrary access");
            dispatch_async_main(^{
                [AlertController showAlertWithTitle:NSLocalizedString(@"1163-TextPhotoLibraryAccessDenied", nil)
                                            message:NSLocalizedString(@"1164-TextYouMustAllowPhotoLibraryAccessInSettings", nil)
                                        buttonTitle:NSLocalizedString(@"33-ButtonOpenSettings", nil)
                                  cancelButtonTitle:QliqLocalizedString(@"4-ButtonCancel")
                                         completion:^(NSUInteger buttonIndex) {
                                             if (buttonIndex == 0) {
                                                 NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                 [[UIApplication sharedApplication] openURL:url];
                                             }
                                         }];
            });
        }
        accessBlock(granted);
    };
    
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if(status == AVAuthorizationStatusAuthorized) {
        localBlock(YES);
    } else if(status == AVAuthorizationStatusDenied){
        localBlock(NO);
    } else if(status == AVAuthorizationStatusRestricted){
        localBlock(NO);
    } else if(status == AVAuthorizationStatusNotDetermined) {
     
        if ([PHPhotoLibrary class]) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus authorizationStatus) {
                 if (authorizationStatus == PHAuthorizationStatusAuthorized) {
                     localBlock(YES);
                 }
                 else {
                     localBlock(NO);
                 }
             }];
        }
        else {
            ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
            [lib enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                localBlock(YES);
            } failureBlock:^(NSError *error) {
                localBlock(NO);
            }];
        }
    }
}


@end
