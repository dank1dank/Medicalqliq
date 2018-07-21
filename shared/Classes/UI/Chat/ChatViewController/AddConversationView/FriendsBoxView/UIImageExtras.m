//
//  UIImageExtras.m
//  AVCam
//
//  Created by Ivan on 31.08.11.
//  Copyright 2011 1618Labs. All rights reserved.
//

#import "UIImageExtras.h"

#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define radiansToDegrees(x) ((x) * 180.0/M_PI)

@implementation UIImage (Extras)

@dynamic aspectRatio, isValid, orientedSize;

+ (UIImage *) imageNamed:(NSString *)name withColor:(UIColor *)color
{
    // load the image
    UIImage *img = [UIImage imageNamed:name];

    return [img imageWithColor:color];
}

- (UIImage *) imageWithColor:(UIColor *)color
{
    UIImage *img = self;

    // begin a new image context, to draw our colored image onto
    UIGraphicsBeginImageContextWithOptions(img.size, NO, [UIScreen mainScreen].scale);

    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetAlpha(context, 0.666);
    // set the fill color
    [color setFill];

    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    // set the blend mode to color burn, and the original image
    CGContextSetBlendMode(context, kCGBlendModeOverlay);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    CGContextDrawImage(context, rect, img.CGImage);

    // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);

    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //return the color-burned image
    return coloredImg;
}

- (void) decompress
{
    UIGraphicsBeginImageContext(CGSizeMake(1, 1));
    [self drawAtPoint:CGPointZero];
    UIGraphicsEndImageContext();
}

- (UIImage *) imageRotatedByDegrees:(CGFloat)degrees andScaledToFitSize:(CGSize)maxSize antialias:(BOOL)antialias
{
    degrees = (int)degrees % 360;
    if (degrees < 0) {
        degrees = 360 + degrees;
    }

    BOOL flip = NO;
    if (fabs(degrees - 90.0f) < FLT_EPSILON || fabs(degrees - 270.0f) < FLT_EPSILON)
    {
        flip = YES;
    }

    CGSize selfSizeFlipped = flip ? CGSizeMake(self.size.height, self.size.width) : self.size;

    // Calculate output size
    CGSize outputSize = self.size;

    // Calcluate scaling
    float widthScale = 1;
    float heightScale = 1;
    if (!CGSizeEqualToSize(maxSize, CGSizeZero)) {
        if (selfSizeFlipped.width > maxSize.width) {
            widthScale = maxSize.width / selfSizeFlipped.width;
        }
        if (selfSizeFlipped.height > maxSize.height) {
            heightScale = maxSize.height / selfSizeFlipped.height;
        }
    }
    float scale = fminf(widthScale, heightScale);

    //DLog(@"outputSize: %@", NSStringFromCGSize(outputSize));

    // Correct output size
    outputSize = CGSizeMake((int)(outputSize.width*scale), (int)(outputSize.height*scale));

    CGSize realOutputSize = outputSize;
    if (antialias) {
        outputSize = CGSizeMake(outputSize.width - 4, outputSize.height - 4);
        scale = fminf(scale*(outputSize.width/realOutputSize.width), scale*(outputSize.height/realOutputSize.height));
    }

    //DLog(@"scale: %f   corrected outputSize: %@", scale, NSStringFromCGSize(outputSize));

    // Create the bitmap context
    UIGraphicsBeginImageContextWithOptions(realOutputSize, NO, 0);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();

    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, realOutputSize.width/2, realOutputSize.height/2);

    CGContextRotateCTM(bitmap, degreesToRadians(degrees));

    CGContextScaleCTM(bitmap, scale, -scale);

    // Now, draw the rotated/scaled image into the context
    CGSize drawSize = flip ? CGSizeMake(self.size.height, self.size.width) : self.size;

    //DLog(@"drawSize: %@", NSStringFromCGSize(drawSize));

    CGContextDrawImage(bitmap, CGRectMake(-drawSize.width/2, -drawSize.height/2, drawSize.width, drawSize.height), self.CGImage);

    if (antialias) {
        CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    //DLog(@"result image size: %fx%f", image.scale * image.size.width, image.scale * image.size.height);

    UIGraphicsEndImageContext();

    return image;
}

- (UIImage *) imageRotatedByDegrees:(CGFloat)degrees andScaledToFitSizeInPixels:(CGSize)maxSize antialias:(BOOL)antialias
{
    float scale = [UIScreen mainScreen].scale;
    maxSize = CGSizeMake(maxSize.width/scale, maxSize.height/scale);
    return [self imageRotatedByDegrees:degrees andScaledToFitSize:maxSize antialias:antialias];
}

- (UIImage *) imageScaledToFitSizeInPixels:(CGSize)size
{
    return [self imageRotatedByDegrees:self.imageOrientationAngle andScaledToFitSizeInPixels:size antialias:NO];
}

- (UIImage *) imageScaledToFitSize:(CGSize)size
{
    return [self imageRotatedByDegrees:self.imageOrientationAngle andScaledToFitSize:size antialias:NO];
}

- (UIImage *) imageScaledToFitSizeAntialiased:(CGSize)size
{
    return [self imageRotatedByDegrees:self.imageOrientationAngle andScaledToFitSize:size antialias:YES];
}

//- (UIImage *) imageByFixingOrientation
//{
//    CGSize size = self.orientedSize;
//
//    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
//
//    CGContextRef context = UIGraphicsGetCurrentContext();
//
//    CGContextTranslateCTM(context, self.orientedSize.width/2, self.orientedSize.height/2);
//    CGContextRotateCTM(context, degreesToRadians(360 - self.imageOrientationAngle));
//    CGContextTranslateCTM(context, -self.orientedSize.width/2, -self.orientedSize.height/2);
//
//    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), [self CGImage]);
//
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//
//    UIGraphicsEndImageContext();
//
//    return image;
//}

+ (float) angleFromOrientation:(UIImageOrientation)orientation
{
    switch (orientation) {
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            return 0.0f;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            return 270.0f;
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            return 180.0f;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            return 90.0f;
    }
}

- (float) aspectRatio
{
    if (self.size.width == 0.0f || self.size.height == 0.0f) {
        return 1; // hack
    }

    return self.size.width / self.size.height;
}

- (BOOL) isValid
{
    return (self.size.width != 0.0f && self.size.height != 0.0f);
}

- (float) imageOrientationAngle
{
    return [[self class] angleFromOrientation:self.imageOrientation];
}

- (CGSize) orientedSize
{
    CGSize flippedSize = CGSizeMake(self.size.height, self.size.width);

    switch (self.imageOrientation) {
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            return self.size;
        default:
            return flippedSize;
    }
}

- (float) orientedAspectRatio
{
    CGSize size = self.orientedSize;

    if (size.width == 0.0f || size.height == 0.0f) {
        return 1; // hack
    }
//
    return size.width / size.height;
}

- (UIImage *) crop:(CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, self.scale);
    [self drawInRect:CGRectMake(-rect.origin.x, -rect.origin.y, self.size.width, self.size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

//- (UIImage *) crop:(CGRect)rect
//{
//    CGSize size = rect.size;
//
//    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
//
//    CGContextRef context = UIGraphicsGetCurrentContext();
//
//    CGContextTranslateCTM(context, self.orientedSize.width/2, self.orientedSize.height/2);
//    CGContextRotateCTM(context, degreesToRadians(self.imageOrientationAngle));
//    CGContextTranslateCTM(context, -self.orientedSize.width/2, -self.orientedSize.height/2);
//
//    CGContextDrawImage(context, CGRectMake(-rect.origin.x, -rect.origin.y, self.orientedSize.height, self.orientedSize.width), [self CGImage]);
//
//    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
//
//    UIGraphicsEndImageContext();
//
//    return image;
//}

#pragma mark - Construct images

+ (UIImage *) shadowImageWithSize:(CGSize)size withRadius:(float)radius withOffset:(CGSize)offset withShadowColor:(UIColor *)shadowColor withCornerRadius:(float)cornerRadius
{
    CGRect rect = CGRectMake(0, 0, size.width + radius*2 + fabs(offset.width), size.height + radius*2 + fabs(offset.height));
    CGFloat minx = CGRectGetMinX(rect) + radius + offset.width, midx = CGRectGetMidX(rect) + offset.width, maxx = CGRectGetMaxX(rect) - radius - offset.width;
    CGFloat miny = CGRectGetMinY(rect) + radius + offset.height, midy = CGRectGetMidY(rect) + offset.height, maxy = CGRectGetMaxY(rect) - radius - offset.height;

    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetShadowWithColor(context, offset, radius, [shadowColor CGColor]);
    CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.5 alpha:1] CGColor]);

    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, cornerRadius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, cornerRadius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, cornerRadius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, cornerRadius);
    CGContextClosePath(context);

    CGContextDrawPath(context, kCGPathFill);

    return UIGraphicsGetImageFromCurrentImageContext();
}

+ (UIImage *) borderImageWithSize:(CGSize)size withBorderGap:(float)borderGap withColor:(UIColor *)color withCornerRadius:(float)radius
{
    CGRect rect = CGRectMake(0, 0, size.width - borderGap*2, size.height - borderGap*2);
    CGFloat minx = CGRectGetMinX(rect) + borderGap/2, midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect) - borderGap/2;
    CGFloat miny = CGRectGetMinY(rect) + borderGap/2, midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect) - borderGap/2;

    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(context, borderGap);
    CGContextSetStrokeColorWithColor(context, [color CGColor]);

    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    CGContextClosePath(context);

    CGContextDrawPath(context, kCGPathStroke);

    return  UIGraphicsGetImageFromCurrentImageContext();
}

+ (UIImage *) roundedRectImageWithSize:(CGSize)size withColor:(UIColor *)color withCornerRadius:(float)radius
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [color CGColor]);

    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    CGContextClosePath(context);

    CGContextDrawPath(context, kCGPathFill);

    return UIGraphicsGetImageFromCurrentImageContext();
}

+ (UIImage *) roundedRectGradientImageWithSize:(CGSize)size withCornerRadius:(float)radius withColors:(NSArray *)colors withPositions:(NSArray *)positions
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextMoveToPoint(context, minx, midy);
    CGContextAddArcToPoint(context, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(context, minx, maxy, minx, midy, radius);
    CGContextClosePath(context);

    CGContextClip(context);

    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *color in colors) {
        id cgcolor = (id) color.CGColor;
        [cgColors addObject:cgcolor];
    }

    CGFloat *locations = NULL;
    if ([positions count]) {
        locations = malloc(sizeof(CGFloat)*[positions count]);

        for (NSNumber *position in positions) {
            NSInteger i = [positions indexOfObject:position];
            locations[i] = [position floatValue];
        }
    }
    
    CGGradientRef gradient = CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)cgColors, locations);

    CGContextDrawLinearGradient(context, gradient, CGPointMake(size.width/2, 0), CGPointMake(size.width/2, size.height), 0);

    CGGradientRelease(gradient);
    if (locations) {
        free(locations);
    }

    return UIGraphicsGetImageFromCurrentImageContext();
}

@end

