//
//  UIImageExtras.h
//  AVCam
//
//  Created by Ivan on 31.08.11.
//  Copyright 2011 1618Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage (Extras)

+ (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color;
- (UIImage *)imageWithColor:(UIColor *)color;

- (void) decompress;

// degrees must be divisable by 90
- (UIImage *) imageRotatedByDegrees:(CGFloat)degrees andScaledToFitSizeInPixels:(CGSize)maxSize antialias:(BOOL)antialias;
- (UIImage *) imageScaledToFitSizeInPixels:(CGSize)size;
- (UIImage *) imageScaledToFitSize:(CGSize)size;
- (UIImage *) imageScaledToFitSizeAntialiased:(CGSize)size;
//- (UIImage *) imageByFixingOrientation;
- (UIImage *) crop:(CGRect)rect;

@property (nonatomic, readonly) float aspectRatio; // width divided by height
@property (nonatomic, readonly) BOOL isValid;

@property (nonatomic, readonly) float imageOrientationAngle;

+ (float) angleFromOrientation:(UIImageOrientation)orientation;

@property (nonatomic, readonly) CGSize orientedSize;
@property (nonatomic, readonly) float orientedAspectRatio;

#pragma mark - Construct images

+ (UIImage *) shadowImageWithSize:(CGSize)size withRadius:(float)radius withOffset:(CGSize)offset withShadowColor:(UIColor *)shadowColor withCornerRadius:(float)cornerRadius;
+ (UIImage *) borderImageWithSize:(CGSize)size withBorderGap:(float)borderGap withColor:(UIColor *)color withCornerRadius:(float)radius;
+ (UIImage *) roundedRectImageWithSize:(CGSize)size withColor:(UIColor *)color withCornerRadius:(float)radius;
+ (UIImage *) roundedRectGradientImageWithSize:(CGSize)size withCornerRadius:(float)radius withColors:(NSArray *)colors withPositions:(NSArray *)positions; // positions may be nil

@end
