//
//  QliqActionSheet.h
//  qliq
//
//  Created by Valerii Lider on 5/5/14.
//
//

#import <UIKit/UIKit.h>

@interface QliqActionSheet : UIView

@property (nonatomic, readonly, assign) NSUInteger cancelButtonIndex;

- (id)initWithTitle:(NSString *)title cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle actionSheetHeader:(UIView *)sheetHeader otherButtonTitles:(NSArray *)otherButtonTitles;

- (void)showInView:(UIView *)view block:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex))dissmissBlock;
- (void)showAsHint:(UIView *)view withPassThroughFrame:(CGRect)passThroughFrame block:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex))dissmissBlock;
- (void)showAsHintFromView:(UIView *)view withPassthroughViews:(NSArray *)views actionBlock:(void(^)(UIActionSheetAction action, NSUInteger buttonIndex))dissmissBlock;
- (void)dismiss;

- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;

- (void)setPassthroughFrame:(CGRect)frame;

@end
