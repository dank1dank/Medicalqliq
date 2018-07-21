//
//  WEPopoverController+LockScreenFix.m
//  qliq
//
//  Created by Developer on 22.11.13.
//
//

#import "WEPopoverController+LockScreenFix.h"
#import <objc/runtime.h>

#define kPresentedFrame     @"PRESENTED-FRAME"
#define kSelfStrongRef      @"SELF-STRONG-REF"
#define kSuperviewRef       @"SUPERVIEW-REF"
#define kArrowDirrections   @"ARROW-DIRRECTIONS"

@interface WEPopoverController ()

- (void)dismissPopoverAnimated:(BOOL)animated;

- (void)presentPopoverFromRect:(CGRect)rect
						inView:(UIView *)view
	  permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
					  animated:(BOOL)animated;
@end

@implementation WEPopoverController (LockScreenFix)


- (void)registerForLockNotification {
    
    objc_setAssociatedObject(self, kSelfStrongRef, self, OBJC_ASSOCIATION_RETAIN);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceLockStatusChangedNotification:)
                                                 name:kDeviceLockStatusChangedNotificationName
                                               object:nil];
}

- (void)unregisterFromLockNotification {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    objc_setAssociatedObject(self, kSelfStrongRef, nil, OBJC_ASSOCIATION_ASSIGN);
}

- (void)onDeviceLockStatusChangedNotification:(NSNotification *)notification {
    
    if ([notification.userInfo[@"locked"] boolValue]) {
        
        [self dismissPopoverAnimated:NO];
    } else {
        
        NSValue *frameValue = objc_getAssociatedObject(self, kPresentedFrame);
        UIView *superview = objc_getAssociatedObject(self, kSuperviewRef);
        NSNumber *arrowDirections = objc_getAssociatedObject(self, kArrowDirrections);
        [self presentPopoverFromRect:[frameValue CGRectValue] inView:superview permittedArrowDirections:arrowDirections.intValue animated:NO];
    }
    
}

- (void)hidePopoverAnimated:(BOOL)animated {
    
    [self unregisterFromLockNotification];
    objc_setAssociatedObject(self, kSelfStrongRef, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(self, kPresentedFrame, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(self, kSuperviewRef, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(self, kArrowDirrections, nil, OBJC_ASSOCIATION_ASSIGN);
    [self dismissPopoverAnimated:animated];
}

- (void)showPopoverFromRect:(CGRect)rect
                     inView:(UIView *)superview
   permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
                   animated:(BOOL)animated {
    
    objc_setAssociatedObject(self, kPresentedFrame, [NSValue valueWithCGRect:rect], OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self, kSuperviewRef, superview, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self, kArrowDirrections, @(arrowDirections), OBJC_ASSOCIATION_RETAIN);
    
    [self presentPopoverFromRect:rect inView:superview permittedArrowDirections:arrowDirections animated:animated];
}

@end
