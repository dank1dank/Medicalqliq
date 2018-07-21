#import "UIColorExtras.h"

@implementation UIColor (Extras)

- (CGColorSpaceModel) colorSpaceModel
{
    return CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
}

- (CGFloat) red
{
    if ([self colorSpaceModel] == kCGColorSpaceModelMonochrome) {
        const CGFloat *c = CGColorGetComponents(self.CGColor);
        return c[0];
    }

    const CGFloat *c = CGColorGetComponents(self.CGColor);
    return c[0];
}

- (CGFloat) green
{
    if ([self colorSpaceModel] == kCGColorSpaceModelMonochrome) {
        const CGFloat *c = CGColorGetComponents(self.CGColor);
        return c[0];
    }

    const CGFloat *c = CGColorGetComponents(self.CGColor);
    return c[1];
}

- (CGFloat) blue
{
    if ([self colorSpaceModel] == kCGColorSpaceModelMonochrome) {
        const CGFloat *c = CGColorGetComponents(self.CGColor);
        return c[0];
    }

    const CGFloat *c = CGColorGetComponents(self.CGColor);
    return c[2];
}

- (CGFloat) alpha
{
    return CGColorGetAlpha(self.CGColor);
}

+ (UIColor *) colorWithR:(int)r g:(int)g b:(int)b
{
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1];
}

+ (UIColor *) colorWithR:(int)r g:(int)g b:(int)b a:(int)a
{
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/255.0];
}

@end

UIColor * UIColorWithRGB(int r, int g, int b)
{
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1];
}

UIColor * UIColorWithRGBA(int r, int g, int b, int a)
{
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/255.0];
}
