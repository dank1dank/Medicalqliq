//
//  CustomIOSAlertView.h
//  CustomIOSAlertView
//
//  Created by Richard on 20/09/2013.
//  Copyright (c) 2013-2015 Wimagguc.
//
//  Lincesed under The MIT License (MIT)
//  http://opensource.org/licenses/MIT
//

#import <UIKit/UIKit.h>
#import "QxQliqStorClient.h"

@protocol QliqAlertViewDelegate

- (void)customIOS7dialogButtonTouchUpInside:(id)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface QliqAlertView : UIView <QliqAlertViewDelegate>

@property (nonatomic, assign) id<QliqAlertViewDelegate> delegate;

@property (nonatomic, strong) UIView *parentView;    // The parent view this 'dialog' is attached to
@property (nonatomic, strong) UIView *dialogView;    // Dialog's container view
@property (nonatomic, strong) UIView *containerView; // Container within the dialog (place your ui elements here)


@property (nonatomic, assign) BOOL useMotionEffects;
@property (nonatomic, assign) BOOL useUploadOption;
@property (nonatomic, assign) BOOL hideSwitch;
@property (nonatomic, assign) BOOL useMultipleQliqSTORsAvialable;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSArray *buttonTitles;

@property (nonatomic, strong) UITextField *destinationGroupTextField;

@property (copy) void (^onButtonTouchUpInside)(QliqAlertView *alertView, int buttonIndex) ;

- (id)initWithInverseColor:(BOOL)inverseColors;

- (void)show;
- (void)close;

- (IBAction)customIOS7dialogButtonTouchUpInside:(UIButton*)sender;
- (void)setOnButtonTouchUpInside:(void (^)(QliqAlertView *alertView, int buttonIndex))onButtonTouchUpInside;

- (void)deviceOrientationDidChange: (NSNotification *)notification;
- (void)dealloc;

/*Upload Detail Option*/
- (BOOL)isQliqSTOROption;
- (BOOL)isEMROption;
- (BOOL)isSaveDefaultOption;
- (NSString *)savingTextFiledFileName;
- (QliqStorPerGroup *)selectedTypeQliqSTORGroup;

- (void)setContainerViewWithImage:(UIImage*)image
                        withTitle:(NSString*)title
                         withText:(NSString*)text
                     withDelegate:(id)delegate
                 useMotionEffects:(BOOL)useMotionEffects;

@end
