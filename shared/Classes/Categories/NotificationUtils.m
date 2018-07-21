//
//  NSObject+Notifications.m
//  Eyeris
//
//  Created by Ivan Zezyulya on 18.11.11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "NotificationUtils.h"
#import <objc/runtime.h>
#import <objc/message.h>

#define kObserveNotificationsList       "ObserveNotificationsList"

@interface ObserverInfo : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, strong) id object;
@property (nonatomic, unsafe_unretained) id observer;
@end

@implementation ObserverInfo

- (void)dealloc
{
    self.name = nil;
    self.object = nil;
    self.observer = nil;
}

@end

@implementation NSObject (NotificationAdditions)

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        
        //dealloc
        SEL originalSelector = NSSelectorFromString(@"dealloc");
        SEL swizzledSelector = @selector(qliqDealloc);
        
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

- (void)qliqDealloc {
    
    // get the list of all ObserverInfo for all notifications to which we was registered
    NSDictionary *selectorToObserversList = (NSDictionary *)objc_getAssociatedObject(self, kObserveNotificationsList);
    for (NSArray *item in [selectorToObserversList allValues]) {
        
        // remove observer
        for (ObserverInfo *observeInfo in item) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:observeInfo.name object:nil];
        }
    }
    // remoe the list of observers
    objc_removeAssociatedObjects(self);

    //It is the correct code
    [self qliqDealloc];
}

- (void) registerForNotification:(NSString *)notificaton selector:(SEL)selector
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:selector name:notificaton object:nil];
}

- (void) unregisterForNotification:(NSString *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notification object:nil];
}

- (void) unregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

@implementation NSNotificationCenter (NotificationAdditions)

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        
        //addObserver:selector:name:object:
        SEL originalSelector = @selector(addObserver:selector:name:object:);
        SEL swizzledSelector = @selector(qliqAddObserver:selector:name:object:);
        
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
        //removeObserver:name:object:
        originalSelector = @selector(removeObserver:name:object:);
        swizzledSelector = @selector(qliqRemoveObserver:name:object:);
        
        originalMethod = class_getInstanceMethod(class, originalSelector);
        swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        didAddMethod =
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
        //removeObserver:
        originalSelector = @selector(removeObserver:);
        swizzledSelector = @selector(qliqRemoveObserver:);
        
        originalMethod = class_getInstanceMethod(class, originalSelector);
        swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        didAddMethod =
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

+ (void) postNotification:(NSString *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
}

+ (void) postNotificationToMainThread:(NSString *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
    });
}

+ (void) postNotification:(NSString *)notification withObject:(id)object
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object];
}

+ (void) postNotificationToMainThread:(NSString *)notification withObject:(id)object
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object];
    });
}

+ (void) postNotification:(NSString *)notification withObject:(id)object userInfo:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object userInfo:userInfo];
}

+ (void) postNotificationToMainThread:(NSString *)notification withObject:(id)object userInfo:(NSDictionary *)userInfo
{
    [NSNotificationCenter postNotificationToMainThread:notification withObject:object userInfo:userInfo needWait:NO];
}

+ (void) postNotificationToMainThread:(NSString *)notification withObject:(id)object userInfo:(NSDictionary *)userInfo needWait:(BOOL)wait
{
    if (wait) {
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object userInfo:userInfo];
        });
    }
    else {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object userInfo:userInfo];
        });
    }
}

+ (void) postNotification:(NSString *)notification userInfo:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil userInfo:userInfo];
}

+ (void) postNotificationToMainThread:(NSString *)notification userInfo:(NSDictionary *)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil userInfo:userInfo];
    });
}

+ (void) notifyOnceForNotification:(NSString *)notificationName usingBlock:(void (^)(NSNotification *note))block
{
    if (!block) {
        return;
    }
    
    __block id observer;
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:notificationName object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer name:notificationName object:nil];
        block(note);
    }];
}

#pragma mark -
#pragma mark hooks for addObserver and removeObserver methods that prevent to add same observer to the same notification name multiple times
#pragma mark -

- (void)qliqAddObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject
{
    //{selector:[ObserverInfo],
    //selector:[ObserverInfo], …}
    NSMutableDictionary *registeredNotifications = (NSMutableDictionary *)objc_getAssociatedObject(observer, kObserveNotificationsList);
    if (!registeredNotifications) {
        registeredNotifications = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(observer, kObserveNotificationsList, registeredNotifications, OBJC_ASSOCIATION_RETAIN);
    }
    
    NSMutableArray *observerInfos = [registeredNotifications objectForKey:NSStringFromSelector(aSelector)];
    if (!observerInfos) {
        observerInfos = [NSMutableArray array];
        [registeredNotifications setObject:observerInfos forKey:NSStringFromSelector(aSelector)];
    }
    
    __block ObserverInfo *observerInfo = nil;
    [observerInfos enumerateObjectsUsingBlock:^void(id obj, NSUInteger idx, BOOL *stop) {
        ObserverInfo *info = obj;
        if ([info.name isEqualToString:aName] && info.object == anObject) {
            observerInfo = info;
            *stop = YES;
        }
    }];
    
    if (!observerInfo) {
        observerInfo = [[ObserverInfo alloc] init];
        [observerInfos addObject:observerInfo];
        
    } else {
        //We should ignore addObserver call if this observer already registered for specified notification name
        
        DDLogWarn(@"Caller (%@) already registered for notification (%@), ignoring second call…", NSStringFromClass([observer class]), aName);
        return;
    }
    
    observerInfo.observer = observer;
    observerInfo.name = aName;
    observerInfo.object = anObject;
    
    [self qliqAddObserver:observer selector:aSelector name:aName object:anObject];
}

- (void)qliqRemoveObserver:(id)anObserver {
    
    NSMutableDictionary *registeredNotifications = (NSMutableDictionary *)objc_getAssociatedObject(anObserver, kObserveNotificationsList);
    for (NSMutableArray *observers in [registeredNotifications allValues]) {
        
        for (int i = 0; i < observers.count; ++i) {
            ObserverInfo *observer = observers[i];
            if (observer.observer == anObserver) {
                [observers removeObjectAtIndex:i];
                --i;
            }
        }
    }
    
    [self qliqRemoveObserver:anObserver];
}

- (void)qliqRemoveObserver:(id)anObserver name:(NSString *)aName object:(id)anObject {
    
    NSMutableDictionary *registeredNotifications = (NSMutableDictionary *)objc_getAssociatedObject(anObserver, kObserveNotificationsList);
    for (NSMutableArray *observers in [registeredNotifications allValues]) {
        
        for (int i = 0; i < observers.count; ++i) {
            ObserverInfo *observer = observers[i];
            if ([observer.name isEqualToString:aName] && observer.observer == anObserver) {
                [observers removeObjectAtIndex:i];
                --i;
            }
        }
    }
    
    [self qliqRemoveObserver:anObserver name:aName object:anObject];
}

@end
