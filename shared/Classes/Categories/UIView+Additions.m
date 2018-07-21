//
//  UIView+Additions.m
//  qliq
//
//  Created by Valerii Lider on 25/11/15.
//
//

#import "UIView+Additions.h"

#import <objc/runtime.h>

@implementation UIView (Additions)

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(addSubview:);
        SEL swizzledSelector = @selector(qliq_addSubview:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        // ...
        // Method originalMethod = class_getClassMethod(class, originalSelector);
        // Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)qliq_addSubview:(UIView *)view {
    
    if (view == self) {
        DDLogError(@"Can't add self as subview. Add view: -%@- to view: -%@-", NSStringFromClass([view class]), NSStringFromClass([self class]) );
        return;
    }
    
    [self qliq_addSubview:view];
}


@end
