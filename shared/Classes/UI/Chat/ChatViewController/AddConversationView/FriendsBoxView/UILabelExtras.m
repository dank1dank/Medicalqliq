//
//  UILabelExtras.m
//  Eyeris
//
//  Created by Ivan Zezyulya on 22.11.11.
//  Copyright (c) 2011 1618Labs. All rights reserved.
//

#import "UILabelExtras.h"
#import "UIViewExtras.h"
#import <QuartzCore/QuartzCore.h>

@implementation UILabel (Extras)

- (void) defaultSettings
{
    self.backgroundColor = [UIColor clearColor];
    self.textAlignment = NSTextAlignmentCenter;
    self.adjustsFontSizeToFitWidth = YES;
}

+ (UILabel *) label
{
    UILabel *label = [UILabel new];
    [label defaultSettings];
    return label;
}

+ (UILabel *) labelWithFrame:(CGRect)frame
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    [label defaultSettings];
    return label;
}

+ (UILabel *) labelWhiteTextWithShadow
{
    UILabel *label = [UILabel new];
    [label defaultSettings];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor darkGrayColor];
    label.shadowOffset = CGSizeMake(0, 0.5);
    return label;
}

+ (UILabel *) labelWhiteHelveticaBoldWithShadow
{
    UILabel *label = [UILabel new];
    [label defaultSettings];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"Helvetica-Bold" size:24.0];

    label.layer.shadowRadius = 5.0;
    label.layer.shadowOpacity = 0.5;
    label.layer.shadowOffset = CGSizeMake(0.0, 3.0);
    label.layer.masksToBounds = NO;
    return label;
}

+ (UILabel *) labelWhiteTextWithShadowWithFrame:(CGRect)frame
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    [label defaultSettings];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor darkGrayColor];
    label.shadowOffset = CGSizeMake(0, 0.5);
    return label;
}

+ (UILabel *) labelGrayTextWithShadow
{
    UILabel *label = [UILabel new];
    [label defaultSettings];
    label.textColor = [UIColor darkGrayColor];
    label.shadowColor = [UIColor lightGrayColor];
    label.shadowOffset = CGSizeMake(0, -0.5);
    return label;
}

+ (UILabel *) labelGrayTextWithShadowWithFrame:(CGRect)frame
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    [label defaultSettings];
    label.textColor = [UIColor darkGrayColor];
    label.shadowColor = [UIColor whiteColor];
    label.shadowOffset = CGSizeMake(0, -0.5);
    return label;
}

+ (UILabel *) glowingLabelWithFontSize:(float)fontSize bold:(BOOL)bold color:(UIColor *)color
{
    UILabel *label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = color;
    label.font = bold ? [UIFont boldSystemFontOfSize:fontSize] : [UIFont systemFontOfSize:fontSize];
    label.layer.shadowColor = [[UIColor blackColor] CGColor];
    label.layer.shadowRadius = 0.5;
    label.layer.shadowOpacity = 1;
    label.layer.shadowOffset = CGSizeZero;
    [label setRasterize];

    return label;
}

- (CGSize) constrainedSizeForMaxSize:(CGSize)maxSize
{
    return [self constrainedSizeForText:self.text forMaxSize:maxSize];
}

- (CGSize) constrainedSizeForText:(NSString *)text forMaxSize:(CGSize)maxSize
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = self.lineBreakMode;
    
    CGRect textRect = [text boundingRectWithSize:maxSize
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName : self.font,
                                                         NSParagraphStyleAttributeName : paragraphStyle.copy}
                                               context:nil];
    CGSize textSize = textRect.size;

    return textSize;
//    return [text sizeWithFont:self.font constrainedToSize:maxSize lineBreakMode:self.lineBreakMode];
}

- (void) setTextColorAnimatable:(UIColor *)color
{
    if ([self.subviews count] != 0) {
        UIView *firstSubview = [self.subviews objectAtIndex:0];
        firstSubview.layer.backgroundColor = color.CGColor;
    }
}

@end
