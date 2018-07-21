//
//  UILabelExtras.h
//  Eyeris
//
//  Created by Ivan Zezyulya on 22.11.11.
//  Copyright (c) 2011 1618Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (Extras)

+ (UILabel *) label;
+ (UILabel *) labelWithFrame:(CGRect)frame;
+ (UILabel *) labelWhiteHelveticaBoldWithShadow;
+ (UILabel *) labelWhiteTextWithShadow;
+ (UILabel *) labelWhiteTextWithShadowWithFrame:(CGRect)frame;
+ (UILabel *) labelGrayTextWithShadow;
+ (UILabel *) labelGrayTextWithShadowWithFrame:(CGRect)frame;

+ (UILabel *) glowingLabelWithFontSize:(float)fontSize bold:(BOOL)bold color:(UIColor *)color;

- (CGSize) constrainedSizeForMaxSize:(CGSize)maxSize;
- (CGSize) constrainedSizeForText:(NSString *)text forMaxSize:(CGSize)maxSize;

- (void) setTextColorAnimatable:(UIColor *)color;

@end
