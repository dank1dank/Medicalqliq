//
//  CustomAlertView.h
//  qliq
//
//  Created by Valerii Lider on 5/17/16.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class CustomAlertView;

@protocol CustomAlertDelegate <NSObject>

- (void)customAlertView:(CustomAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface CustomAlertView : UIView


@property (nonatomic, strong) NSMutableDictionary *info;
@property (nonatomic, assign) id<CustomAlertDelegate> delegate;

- (instancetype)initWithTitle:(NSString *)title
            message:(NSString *)message
           delegate:(id)alertDelegate
          needTextField:(BOOL)needTextField
   requestButtonTitles:(NSArray *)requestButtonTitles;

- (void)showInView:(UIView*)view withDismissBlock:(void(^)(NSInteger buttonIndex, NSString *textFieldText))block;

- (void)setRequestButtonEnabled:(BOOL)enabled;

@end


