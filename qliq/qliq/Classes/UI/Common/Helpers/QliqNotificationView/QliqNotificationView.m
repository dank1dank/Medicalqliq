//
//  QliqNotificationView.m
//  qliq
//
//  Created by Valerii Lider on 28/10/15.
//
//

#import "QliqNotificationView.h"

#import "ConversationViewController.h"
#import "ConversationDBService.h"
#import "Conversation.h"
#import "MainViewController.h"
#import "ACPStaticImagesAlternative.h"
#import "UIDevice-Hardware.h"


@implementation QliqNotificationView

- (void)dealloc {
    self.avatarImageView = nil;
    self.titleLabel = nil;
    self.descriptionLabel = nil;
    self.closeButton = nil;
}

- (instancetype)init {
    self = [self initializeSubviews];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
    }
    
    return self;
}

- (instancetype)initializeSubviews {
    
    id view = nil;
    
    for (id subView in [appDelegate.window subviews]) {
        if ([subView isKindOfClass:[self class]]) {
            view = subView;
            break;
        }
    }
    
    if (view == nil) {
        view = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    }
    self.activityView.hidden = YES;
    
    return view;
}

- (void)present {
    
    if (![self shouldShowNotificationView]) {
        return;
    }
    
    appDelegate.window.windowLevel = UIWindowLevelStatusBar+1;
    
    BOOL skipInitialFrame = NO;
    for (NSLayoutConstraint *item in appDelegate.window.constraints) {
        if (item.firstItem == self && item.firstAttribute == NSLayoutAttributeTop) {
            if(0 == item.constant) {
                skipInitialFrame = YES;
                break;
            }
        }
    }
    if (!skipInitialFrame) {
        self.frame = CGRectMake(0, -64, CGRectGetWidth(appDelegate.window.bounds), 64);
    }
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [appDelegate.window addSubview:self];
    
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:appDelegate.window attribute:NSLayoutAttributeTop multiplier:1.0f constant:-64.0f];
    NSLayoutConstraint *leadig = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:appDelegate.window attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f];
    NSLayoutConstraint *trailing = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:appDelegate.window attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:64.0];
    isIPhoneX {
        if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
            height.constant = 100.f;
            self.avatarHeight.constant = 60;
        }
    }
    
    [self addConstraint:height];
    [appDelegate.window addConstraints:@[top, leadig, trailing]];
    
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2;
    
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView animateWithDuration:0.35f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.9f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        top.constant = 0.0f;
        
        [appDelegate.window layoutIfNeeded];
    } completion:^(BOOL finished) {
        
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf removeNotificationView];
        });
    }];
}

- (void)presentForOnCall {
    
    if (![self shouldShowNotificationView]) {
        return;
    }
    
    [self configureActivityView];

    appDelegate.window.windowLevel = UIWindowLevelStatusBar+1;
    
    BOOL skipInitialFrame = NO;
    
    for (NSLayoutConstraint *item in appDelegate.window.constraints) {
        if (item.firstItem == self && item.firstAttribute == NSLayoutAttributeTop) {
            if(0 == item.constant) {
                skipInitialFrame = YES;
                break;
            }
        }
    }
    
    if (!skipInitialFrame) {
        self.frame = CGRectMake(0, -64, CGRectGetWidth(appDelegate.window.bounds), 64);
    }
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [appDelegate.window addSubview:self];
    
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:appDelegate.window attribute:NSLayoutAttributeTop multiplier:1.0f constant:-64.0f];
    NSLayoutConstraint *leadig = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:appDelegate.window attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f];
    NSLayoutConstraint *trailing = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:appDelegate.window attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:64.0];
    isIPhoneX {
        if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
            height.constant = 100.f;
            self.avatarHeight.constant = 60;
        }
    }
    
    [self addConstraint:height];
    [appDelegate.window addConstraints:@[top, leadig, trailing]];
    
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2;
    
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView animateWithDuration:0.35f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.9f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        top.constant = 0.0f;
        
        [appDelegate.window layoutIfNeeded];
    } completion:nil];
}

- (void)presentSendingMessageFailed {
    
    appDelegate.window.windowLevel = UIWindowLevelStatusBar+1;
    
    BOOL skipInitialFrame = NO;
    for (NSLayoutConstraint *item in appDelegate.window.constraints) {
        if (item.firstItem == self && item.firstAttribute == NSLayoutAttributeTop) {
            if(0 == item.constant) {
                skipInitialFrame = YES;
                break;
            }
        }
    }
    if (!skipInitialFrame) {
        self.frame = CGRectMake(0, -64, CGRectGetWidth(appDelegate.window.bounds), 64);
    }
    
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [appDelegate.window addSubview:self];
    
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:appDelegate.window attribute:NSLayoutAttributeTop multiplier:1.0f constant:-64.0f];
    NSLayoutConstraint *leadig = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:appDelegate.window attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f];
    NSLayoutConstraint *trailing = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:appDelegate.window attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:0.0f];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:64.0];
    isIPhoneX {
        if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
            height.constant = 100.f;
            self.avatarHeight.constant = 60;
        }
    }
    
    [self addConstraint:height];
    [appDelegate.window addConstraints:@[top, leadig, trailing]];
    
    self.avatarImageView.layer.masksToBounds = YES;
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2;
    
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView animateWithDuration:0.35f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.9f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        top.constant = 0.0f;
        
        [appDelegate.window layoutIfNeeded];
    } completion:^(BOOL finished) {
        
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf removeNotificationView];
        });
    }];
}

#pragma mark - Actions

- (IBAction)tapNotificationView:(id)sender {
    [self openConversation];
}

- (IBAction)didPressCloseButton:(id)sender {
    [self removeNotificationView];
}

#pragma mark - Private

- (BOOL)shouldShowNotificationView {
    BOOL shouldShow = YES;
    
    if ([appDelegate.navigationController.topViewController isKindOfClass:[ConversationViewController class]]) {
        
        ConversationViewController *conversationVC = (ConversationViewController *)appDelegate.navigationController.topViewController;

        if (conversationVC.conversation.conversationId == self.converationId) {
            shouldShow = NO;
        }
    }

    return shouldShow;
}

- (void)openConversation {
    
    if (appDelegate.idleController.lockedIdle) {
        return;
    }
    
    for (id controller in appDelegate.navigationController.viewControllers) {
        if ([controller isKindOfClass:[MainViewController class]]) {
            
            Conversation *conversation = [[ConversationDBService sharedService] getConversationWithId:@(self.converationId)];
            if (conversation) {
                
                //                [appDelegate.navigationController popToViewController:controller animated:NO];
                
                ConversationViewController *controller = [kMainStoryboard instantiateViewControllerWithIdentifier:NSStringFromClass([ConversationViewController class])];
                controller.conversation = conversation;
                
                [appDelegate.navigationController pushViewController:controller animated:YES];
                
                [self removeNotificationView];
            }
        }
    }
}

- (void)removeNotificationView {
    
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView animateWithDuration:0.35 delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.9f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        
        for (NSLayoutConstraint *item in appDelegate.window.constraints) {
            if (item.firstItem == self && item.firstAttribute == NSLayoutAttributeTop) {
                item.constant = -64.0f;
                
                break;
            }
        }
        
        [appDelegate.window layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
    appDelegate.window.windowLevel = UIWindowLevelNormal;
}

- (void)configureActivityView {
    
    if (!self.activityView) {
        self.activityView = [ACPDownloadView new];
    }
    
    CGFloat activityViewSize = 30.f;
    [self.activityView setFrame:CGRectMake(self.closeButton.frame.origin.x + (self.closeButton.frame.size.width - activityViewSize)/2 - 10.f, self.closeButton.frame.origin.y + (self.closeButton.frame.size.height - activityViewSize)/2, activityViewSize, activityViewSize)];
    
    self.activityView.hidden = NO;
    self.activityView.backgroundColor = [UIColor clearColor];
    self.activityView.clearsContextBeforeDrawing = YES;
    [self.activityView setTintColor:RGBa(24.f, 122.f, 181.f, 0.75)];
   
    ACPStaticImagesAlternative * myOwnImages = [ACPStaticImagesAlternative new];
    [myOwnImages setStrokeColor:[UIColor whiteColor]];
    [self.activityView setImages:myOwnImages];
    
    [self.activityView setIndicatorStatus:ACPDownloadStatusIndeterminate];
    [self addSubview:self.activityView];
}

@end
