//
//  UIButton+Blocks.m
//  qliq
//
//  Created by Valerii Lider on 12/12/13.
//
//

#import "UIButton+Blocks.h"
#include <objc/runtime.h>

#define kUIControlEventTouchDown            @"UIControlEventTouchDown"
#define kUIControlEventTouchDownRepeat      @"UIControlEventTouchDownRepeat"
#define kUIControlEventTouchDragInside      @"UIControlEventTouchDragInside"
#define kUIControlEventTouchDragOutside     @"UIControlEventTouchDragOutside"
#define kUIControlEventTouchDragEnter       @"UIControlEventTouchDragEnter"
#define kUIControlEventTouchDragExit        @"UIControlEventTouchDragExit"
#define kUIControlEventTouchUpInside        @"UIControlEventTouchUpInside"
#define kUIControlEventTouchUpOutside       @"UIControlEventTouchUpOutside"

@implementation UIButton (Blocks)

- (void)dealloc
{
    objc_removeAssociatedObjects(self);
}

- (void)addBlock:(void (^)(UIButton *))actionBlock forControlEvents:(UIControlEvents)controlEvents {
    
    if (controlEvents & UIControlEventTouchDown) {
        
        [self addTarget:self action:@selector(onUIControlEventTouchDown) forControlEvents:controlEvents];
        objc_setAssociatedObject(self, kUIControlEventTouchDown, actionBlock, OBJC_ASSOCIATION_COPY);
    }
    if (controlEvents & UIControlEventTouchDownRepeat) {
        
        [self addTarget:self action:@selector(onUIControlEventTouchDownRepeat) forControlEvents:controlEvents];
        objc_setAssociatedObject(self, kUIControlEventTouchDownRepeat, actionBlock, OBJC_ASSOCIATION_COPY);
    }
    if (controlEvents & UIControlEventTouchDragInside) {
        
        [self addTarget:self action:@selector(onUIControlEventTouchDragInside) forControlEvents:controlEvents];
        objc_setAssociatedObject(self, kUIControlEventTouchDragInside, actionBlock, OBJC_ASSOCIATION_COPY);
    }
    if (controlEvents & UIControlEventTouchDragOutside) {
        
        [self addTarget:self action:@selector(onUIControlEventTouchDragOutside) forControlEvents:controlEvents];
        objc_setAssociatedObject(self, kUIControlEventTouchDragOutside, actionBlock, OBJC_ASSOCIATION_COPY);
    }
    if (controlEvents & UIControlEventTouchDragEnter) {
        
        [self addTarget:self action:@selector(onUIControlEventTouchDragEnter) forControlEvents:controlEvents];
        objc_setAssociatedObject(self, kUIControlEventTouchDragEnter, actionBlock, OBJC_ASSOCIATION_COPY);
    }
    if (controlEvents & UIControlEventTouchDragExit) {
        
        [self addTarget:self action:@selector(onUIControlEventTouchDragExit) forControlEvents:controlEvents];
        objc_setAssociatedObject(self, kUIControlEventTouchDragExit, actionBlock, OBJC_ASSOCIATION_COPY);
    }
    if (controlEvents & UIControlEventTouchUpInside) {
        
        [self addTarget:self action:@selector(onUIControlEventTouchUpInside) forControlEvents:controlEvents];
        objc_setAssociatedObject(self, kUIControlEventTouchUpInside, actionBlock, OBJC_ASSOCIATION_COPY);
    }
    if (controlEvents & UIControlEventTouchUpOutside) {
        
        [self addTarget:self action:@selector(onUIControlEventTouchUpOutside) forControlEvents:controlEvents];
        objc_setAssociatedObject(self, kUIControlEventTouchUpOutside, actionBlock, OBJC_ASSOCIATION_COPY);
    }
}

- (void)onUIControlEventTouchDown {

    void (^actionBlock)(UIButton *) = objc_getAssociatedObject(self, kUIControlEventTouchDown);
    
    if (actionBlock) {
        actionBlock(self);
    }
}

- (void)onUIControlEventTouchDownRepeat {
    
    void (^actionBlock)(UIButton *) = objc_getAssociatedObject(self, kUIControlEventTouchDownRepeat);
    
    if (actionBlock) {
        actionBlock(self);
    }
}

- (void)onUIControlEventTouchDragInside {
    
    void (^actionBlock)(UIButton *) = objc_getAssociatedObject(self, kUIControlEventTouchDragInside);
    
    if (actionBlock) {
        actionBlock(self);
    }
}

- (void)onUIControlEventTouchDragOutside {
    
    void (^actionBlock)(UIButton *) = objc_getAssociatedObject(self, kUIControlEventTouchDragOutside);
    
    if (actionBlock) {
        actionBlock(self);
    }
}

- (void)onUIControlEventTouchDragEnter {
    
    void (^actionBlock)(UIButton *) = objc_getAssociatedObject(self, kUIControlEventTouchDragEnter);
    
    if (actionBlock) {
        actionBlock(self);
    }
}

- (void)onUIControlEventTouchDragExit {
    
    void (^actionBlock)(UIButton *) = objc_getAssociatedObject(self, kUIControlEventTouchDragExit);
    
    if (actionBlock) {
        actionBlock(self);
    }
}

- (void)onUIControlEventTouchUpInside {
    
    void (^actionBlock)(UIButton *) = objc_getAssociatedObject(self, kUIControlEventTouchUpInside);
    
    if (actionBlock) {
        actionBlock(self);
    }
}

- (void)onUIControlEventTouchUpOutside {
    
    void (^actionBlock)(UIButton *) = objc_getAssociatedObject(self, kUIControlEventTouchUpOutside);
    
    if (actionBlock) {
        actionBlock(self);
    }
}
@end
