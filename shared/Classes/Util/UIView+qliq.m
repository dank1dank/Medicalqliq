//
//  UIView+qliq.m
//  qliq
//
//  Created by Valeriy Lider on 6/19/14.
//
//

#import "UIView+qliq.h"
#import <objc/runtime.h>
#import "Log.h"

@implementation UIView (Tracking)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        
        SEL originalSelector = @selector(addSubview:);
        SEL swizzledSelector = @selector(customAddSubview:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
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

#pragma mark - Method Swizzling

- (void)customAddSubview:(id)sender {
    
    if (![self isEqual:sender]) {
        [self customAddSubview:sender];
    }else{
        DDLogCError(@"View %@ of kind %@ tries to addSubview with them self", self, NSStringFromClass([self class]) );
        DDLogCError(@"\nSender class %@",NSStringFromClass([sender class]));
        DDLogCError(@"\nStack trace: %@", [NSThread callStackSymbols]);
        //DDLogCError(@"\nParrent class %@",NSStringFromClass([ class]));
        
        //abort();
    }
}

@end
