//
//  UIViewExtras.m
//  OwlCity
//
//  Created by Ivan on 12.01.11.
//  Copyright 2011 Al Digit. All rights reserved.
//

#import "UIViewExtras.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (Extras)

static void dumpViews(UIView* view, NSString *text, NSString *indent)
{
    Class cl = [view class];
    NSString *classDescription = [cl description];

    while ([cl superclass])
    {
        cl = [cl superclass];
        classDescription = [classDescription stringByAppendingFormat:@":%@", [cl description]];
    }

    if ([text compare:@""] == NSOrderedSame)
    {
        NSLog(@"%@ %@", classDescription, NSStringFromCGRect(view.frame));
    }
    else
    {
        NSLog(@"%@ %@ %@", text, classDescription, NSStringFromCGRect(view.frame));
    }

    for (NSUInteger i = 0; i < [view.subviews count]; i++)
    {
        UIView *subView = [view.subviews objectAtIndex:i];
        NSString *newIndent = [[NSString alloc] initWithFormat:@"  %@", indent];
        NSString *msg = [[NSString alloc] initWithFormat:@"%@%lu:", newIndent, (unsigned long)i];
        dumpViews(subView, msg, newIndent);
    }
}

- (void) dumpSubviews
{
    dumpViews(self, @"", @"");
}

- (void) removeSubviews
{
    while ([self.subviews count])
    {
        UIView *child = self.subviews.lastObject;
        [child removeFromSuperview];
    }
}

- (void) removeFromSuperViewWithAnimation:(float)animationDuration
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
    [UIView setAnimationDuration:animationDuration];
    self.alpha = 0.0;
    [UIView commitAnimations];
}

- (void) makeVisibleWithAnimation:(float) animationDuration
{
    if (!self.hidden)
        return;

    self.alpha = 0.0;
    self.hidden = NO;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
        self.alpha = 1.0;
    [UIView commitAnimations];
}

- (UIImage *) screenshot
{
    return [self screenshotAtFrame:self.bounds];
}

- (UIImage *) screenshotAtFrame:(CGRect)frame
{
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, CGAffineTransformMakeTranslation(-frame.origin.x, -frame.origin.y));
    [self.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

- (void) saveScreenshotToFile:(NSString *)filename
{
    UIImage *image = [self screenshot];
    NSData *data = UIImagePNGRepresentation(image);

    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    BOOL status = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];

    DDLogInfo(@"%@created file at %@", status ? @"" : @"NOT ", path);
}

- (void) setShadowWithRadius:(float)radius opacity:(float)opacity offset:(CGSize)offset color:(UIColor *)color;
{
    self.layer.shadowRadius = radius;
    self.layer.shadowColor = color.CGColor;
    self.layer.shadowOpacity = opacity;
    self.layer.shadowOffset = offset;
}

- (void) setShadowWithRadius:(float)radius opacity:(float)opacity offset:(CGSize)offset
{
    [self setShadowWithRadius:radius opacity:opacity offset:offset color:[UIColor blackColor]];
}

- (void) setShadowWithRadius:(float)radius opacity:(float)opacity
{
    [self setShadowWithRadius:radius opacity:opacity offset:CGSizeZero];
}

- (void) setRasterize
{
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (UIView *) findFirstSubviewOfClass:(Class)class
{
    if ([self isKindOfClass:class]) {
        return self;
    }

    for (UIView *view in self.subviews) {
        UIView *result = [view findFirstSubviewOfClass:class];
        if (result) {
            return result;
        }
    }

    return nil;
}

+ (void) animate:(dispatch_block_t)animations
{
    [self animateWithDuration:0.3 animations:animations];
}

+ (void) animate:(dispatch_block_t)animations completion:(dispatch_block_t)completion
{
    [self animateWithDuration:0.3 animations:animations completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

@end
