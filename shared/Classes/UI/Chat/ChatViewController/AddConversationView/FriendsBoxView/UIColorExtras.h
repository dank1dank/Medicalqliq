#import <UIKit/UIKit.h>

@interface UIColor (Extras)

@property (nonatomic, readonly) CGFloat red;
@property (nonatomic, readonly) CGFloat green;
@property (nonatomic, readonly) CGFloat blue;
@property (nonatomic, readonly) CGFloat alpha;

+ (UIColor *) colorWithR:(int)r g:(int)g b:(int)b;
+ (UIColor *) colorWithR:(int)r g:(int)g b:(int)b a:(int)a;

@end

UIColor * UIColorWithRGB(int r, int g, int b);
UIColor * UIColorWithRGBA(int r, int g, int b, int a);

