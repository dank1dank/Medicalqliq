//
//  QliqHelper.h
//  qliq
//
//  Created by Valerii Lider on 27/11/15.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PickerMode) {
    PickerModePhoto = 1,
    PickerModeVideo = 2,
    PickerModePhotoAndVideo = 3,
    PickerModeLibrary = 4
};

typedef void (^ReturnPickerBlock)(UIImagePickerController *picker, NSError *error);

extern NSString *const kUDKeyShowSignUpButton;

@interface QliqHelper : NSObject

+ (QliqHelper *)sharedInstance;

+ (NSString *)currentBuildVersion;
+ (NSString *)currentVersion;

+ (void)shouldShowSignUpButton:(BOOL)shouldShow;

+ (void)getPickerForMode:(PickerMode)mode forViewController:(id)viewController returnPicker:(ReturnPickerBlock)returnPickerBlock;

@end
