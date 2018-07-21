//
//  StartView.m
//  qliq
//
//  Created by Aleksey Garbarev on 07.06.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StartView.h"
#import "FailedAttemptsController.h"
#import "StretchableButton.h"
#import "KeychainService.h"
#import "SVProgressHUD.h"
#import "UIDevice-Hardware.h"

#import "CustomActionSheet.h"

@implementation StartView{
    StartViewType viewType;
    
    void(^demoBlock)(void);
    void(^registerBlock)(void);
    void(^loginBlock)(void);
    void(^unlock)(void);
    
    FailedAttemptsController * failedAttemptsController;
}

@synthesize shouldHideStatusBar;

- (void)didMoveToSuperview{
    //Show status bar only when superview is not nil
    if (self.shouldHideStatusBar) [[UIApplication sharedApplication] setStatusBarHidden:self.superview != nil];
    
    [super didMoveToSuperview];
}

- (void)removeFromSuperviewAnimation:(void(^)(void))animationBlock complete:(void(^)(BOOL finished)) completeBlock{
    
    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alpha = 0;
        if (self.shouldHideStatusBar) [[UIApplication sharedApplication] setStatusBarHidden:NO];

         if (animationBlock) animationBlock();
        
    } completion:^(BOOL l){
        [self removeFromSuperview];
        self.alpha = 1;
        if (completeBlock) completeBlock(YES);
    }];
}

- (void)removeFromSuperviewAnimationComplete:(void(^)(BOOL finished)) animationBlock{
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    [UIView animateWithDuration:0.3f delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alpha = 0;
        if (self.shouldHideStatusBar) [[UIApplication sharedApplication] setStatusBarHidden:NO];
//        [window.rootViewController.view setNeedsLayout];
        [[self superview] layoutSubviews];
        [[[self superview] superview] layoutSubviews];
        [window.rootViewController.view layoutSubviews];
        
    } completion:^(BOOL l){
        [self removeFromSuperview];
        self.alpha = 1;
        if (animationBlock) animationBlock(YES);
    }];
}

- (UILabel *) labelWithText:(NSString *)text{
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(20, 210, 280, 90)];
    label.text = text;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Heveltica-Bold" size:19];
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 4;
    label.textAlignment = UITextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    return label;
}

- (StartViewType) type{
    return viewType;
}

- (NSString *) timeStringForTimeInterval:(NSTimeInterval) timeInterval{
    
    NSUInteger minutes = timeInterval/60;
    NSUInteger secunds = timeInterval - minutes * 60;
    BOOL showMinutes = minutes > 0;
    BOOL showSeconds = (int)timeInterval % 60 != 0;
    NSString * minutesString = showMinutes ? [NSString stringWithFormat:@"%d minutes",minutes] : @"";
    NSString * secondsString = showSeconds ? [NSString stringWithFormat:@"%d seconds",secunds]  : @"";
    
    return [NSString stringWithFormat:@"%@%@%@",minutesString,showMinutes&&showSeconds?@" ":@"",secondsString];
}

- (void) setType:(StartViewType) type animated:(BOOL)animated{
    viewType = type;
    
    //remove buttons of previous type
    NSArray * subviews = [self subviews];
    for (UIView * subview in subviews){
        if (animated){
            [UIView animateWithDuration:0.5 animations:^{
                subview.alpha = 0;
            } completion:^(BOOL finished) {
                [subview removeFromSuperview];
            }];
        }else{
            [subview removeFromSuperview];
        }
    }
    
    //create new buttons
    switch (viewType) {
        case StartViewTypeFirstLaunch:{
            
            UIButton *loginButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 240, 200, 40)];
            [loginButton setImage:[UIImage imageNamed:@"LoginSplashLoginBtn"] forState:UIControlStateNormal];
            [self addSubview:loginButton];
            [loginButton addTarget:self action:@selector(loginButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            
            // Register button is temporarly disabled
            UIButton * registerButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 300, 200, 40)];
            [registerButton setImage:[UIImage imageNamed:@"LoginSplashRegisterBtn"] forState:UIControlStateNormal];
            [self addSubview:registerButton];
            [registerButton addTarget:self action:@selector(registerButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            
            UIButton *demoButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 360, 200, 40)];
            [demoButton setImage:[UIImage imageNamed:@"LoginSplashWatchDemoBtn"] forState:UIControlStateNormal];
            [self addSubview:demoButton];
            [demoButton addTarget:self action:@selector(demoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            
            UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            infoButton.frame = CGRectMake(self.frame.size.width - 40.f, self.frame.size.height - 40.f, 40.f, 40.f);
            [infoButton addTarget:self action:@selector(onInfoButton:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:infoButton];
            
            break;
        }
        case StartViewTypeLock:{
            
            [self addSubview:[self labelWithText:@"This application has been remotely locked."]];
            
            UIButton * loginButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 300, 200, 40)];
            [loginButton setImage:[UIImage imageNamed:@"LoginSplashUnlockBtn"] forState:UIControlStateNormal];
            [self addSubview:loginButton];
            [loginButton addTarget:self action:@selector(contactAdminButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            break;
        }
        case StartViewTypeWipe:{
            [[KeychainService sharedService] saveWipeState:@"WipedAlready"];
            AppDelegate *appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
            [appDelegate.currentDeviceStatusController loadStatusesFromKeychain];
            [self addSubview:[self labelWithText:@"Conversations on this device have been remotely wiped."]];
            
            UIButton * loginButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 300, 200, 40)];
            [loginButton setImage:[UIImage imageNamed:@"LoginSplashContinueBtn"] forState:UIControlStateNormal];
            [self addSubview:loginButton];
            [loginButton addTarget:self action:@selector(loginButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            break;
        }
        case StartViewTypeAttemptsLock:{
            failedAttemptsController = [[FailedAttemptsController alloc] init];
            
            NSUInteger maxAttemps = [failedAttemptsController maxAttempts];
            NSTimeInterval time = [failedAttemptsController timeIntervalToUnlock];
            NSString * lockingString = [NSString stringWithFormat:@"You have tried to login incorrectly %d times.\nSo please wait %@ to try again",maxAttemps,[self timeStringForTimeInterval:time]];
            UILabel * failedAttempsLabel = [self labelWithText:lockingString];

            [self addSubview:failedAttempsLabel];
            
            UIButton *unlockButton = [[UIButton alloc] initWithFrame:CGRectMake(60, 350, 200, 40)];
            [unlockButton setImage:[UIImage imageNamed:@"LoginSplashUnlockBtn"] forState:UIControlStateNormal];
            [self addSubview:unlockButton];
            [unlockButton addTarget:self action:@selector(contactAdminButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            
            // Weak reference to login block to avoid compiler warning on retain cycle for self when using it directly in the block below
            __weak void(^loginBlockWeakRef)(void) = loginBlock;
            StartView* startView = self;
            [failedAttemptsController setCountdownBlock:^(NSTimeInterval invervalToUnlock) {
                if (invervalToUnlock > 1){
                    failedAttempsLabel.text = [NSString stringWithFormat:@"You have tried to login incorrectly %d times.\nSo please wait %@ to try again",maxAttemps,[startView timeStringForTimeInterval:invervalToUnlock]];
                }else{
                    failedAttempsLabel.text = @"";
                    if (loginBlockWeakRef) loginBlockWeakRef();
                }
            }];
            
            break;
        }
        case StartViewTypeNone:{
            UIImageView * splash = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
            splash.frame = self.bounds;
            [self addSubview:splash];
            break;
        }
    }
    
    if (animated){
        for (UIView * subview in self.subviews){
            if (![subviews containsObject:subview]){
                subview.alpha = 0;
                [UIView animateWithDuration:0.5 animations:^{
                    subview.alpha = 1;
                }];
            }
        }
    }
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if (self) {
        // Initialization code
        if (screenRect.size.height == 568.0f)
            self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"LoginSplash-568h"]];
        else
            self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"LoginSplash"]];
        
    }
    return self;
}

- (id) initWithType:(StartViewType) type andFrame:(CGRect)frame{
    self = [self initWithFrame:frame];
    if (self){
        [self setType:type animated:NO];
    }
    return self;
}


- (void) contactAdminButtonAction:(UIButton *) _button{
    if (unlock) unlock();
}
- (void) demoButtonAction:(UIButton *) _button{
    if (demoBlock) demoBlock();
    
}

- (void) registerButtonAction:(UIButton *) _button{
    if (registerBlock) registerBlock();
    
}
- (void) loginButtonAction:(UIButton *) _button{
    AppDelegate *appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
    // If the first install launch, show action sheet to let the user know that the user
    // should say ok when the iOS asks user for permission for push notifications
    //
    if ([[UIDevice currentDevice] isSimulator] == NO )
    {
        DDLogSupport(@"Showing Popup - qliq requires push notifications");
        CustomActionSheet *actionSheet = [[CustomActionSheet alloc] initWithTitle:@"qliq requires push notifications"
                                                                cancelButtonTitle:@"OK"
                                                                otherButtonTitles:nil];
        [actionSheet showInView:self block:^(UIActionSheetAction action, NSUInteger buttonIndex) {
            
            if (UIActionSheetActionDidDissmiss == action) {
                [appDelegate setupFirstInstallPushnotifications];
                if (loginBlock) loginBlock();
            }
        }];
    } else {
        if (loginBlock) loginBlock();
    }
}

- (void) unlockButtonAction:(UIButton *) _button
{
}

- (void)onInfoButton:(UIButton *)button {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SVProgressHUDDidReceiveTouchEventNotification object:nil];
}

- (void) setUnlockBlock:(void(^)(void))_unlockBlock{
    unlock = [_unlockBlock copy];
}
- (void) setDidDemoBlock:(void(^)(void))_demoBlock{
    demoBlock = [_demoBlock copy];
}

- (void) setDidRegisterBlock:(void(^)(void))_registerBlock{
    registerBlock = [_registerBlock copy];
}

- (void) setDidLoginBlock:(void(^)(void))_loginBlock{
    loginBlock = [_loginBlock copy];
}

- (void) dealloc{
    NSLog(@"StartView dealloc");
    registerBlock = nil;
    loginBlock = nil;
    demoBlock = nil;
}



@end
