//
//  AlertController.h
//  qliq
//
//  Created by Valerii Lider on 5/1/18.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AlertController : UIAlertController

+ (AlertController *)sharedInstance;
+ (void) showAlertWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle cancelButtonTitle:(NSString *)cancelButtonTitle completion:(void(^)(NSUInteger buttonIndex))completion;
+ (void) showAlertWithTitle:(NSString *)title message:(NSString *)message withTitleButtons:(NSArray *)buttonsArray cancelButtonTitle:(NSString *)cancelButtonTitle completion:(void (^)(NSUInteger buttonIndex))completion;
+ (void) showActionSheetAlertWithTitle:(NSString *)title message:(NSString *)message withTitleButtons:(NSArray *)buttonsArray cancelButtonTitle:(NSString *)cancelButtonTitle completion:(void (^)(NSUInteger buttonIndex))completion;
+ (void) showActionSheetAlertWithTitle:(NSString *)title message:(NSString *)message withTitleButtons:(NSArray *)buttonsArray cancelButtonTitle:(NSString *)cancelButtonTitle inController:(UIViewController *)controller completion:(void (^)(NSUInteger buttonIndex))completion;
+ (void) showActionSheetAlertWithTitle:(NSString *)title message:(NSString *)message withTitleButtons:(NSArray *)buttonsArray destructiveButtonTitle:(NSString *)destructiveButtonTitle cancelButtonTitle:(NSString *)cancelButtonTitle inController:(UIViewController *)controller completion:(void (^)(NSUInteger buttonIndex))completion;
@end

