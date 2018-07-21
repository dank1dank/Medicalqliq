//
//  UIViewExtras.h
//  OwlCity
//
//  Created by Ivan on 12.01.11.
//  Copyright 2011 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Extras)

- (void) dumpSubviews;
- (void) removeSubviews;

- (void) removeFromSuperViewWithAnimation:(float)animationDuration;

- (void) makeVisibleWithAnimation:(float)animationDuration;

- (UIImage *) screenshot;
- (UIImage *) screenshotAtFrame:(CGRect)frame;
- (void) saveScreenshotToFile:(NSString *)filename; // file will be saved in application's tmp directory

- (void) setShadowWithRadius:(float)radius opacity:(float)opacity offset:(CGSize)offset color:(UIColor *)color;
- (void) setShadowWithRadius:(float)radius opacity:(float)opacity offset:(CGSize)offset;
- (void) setShadowWithRadius:(float)radius opacity:(float)opacity;

- (void) setRasterize;

- (UIView *) findFirstSubviewOfClass:(Class)cl;

+ (void) animate:(dispatch_block_t)animations;
+ (void) animate:(dispatch_block_t)animations completion:(dispatch_block_t)completion;

@end

//
// Place method: - (void) initYourClass before call to this macro.
//
#define STANDARD_UIVIEW_INITS(ClassName) \
- (id) init {                            \
    if ((self = [super init])) {         \
        [self init##ClassName];          \
    }                                    \
    return self;                         \
}                                        \
                                         \
- (id) initWithCoder:(NSCoder *)coder {  \
    if ((self = [super init])) {         \
        [self init##ClassName];          \
    }                                    \
    return self;                         \
}                                        \
                                         \
- (id) initWithFrame:(CGRect)frame              \
{                                               \
    if ((self = [super initWithFrame:frame])) { \
        [self init##ClassName];                 \
    }                                           \
    return self;                                \
}
