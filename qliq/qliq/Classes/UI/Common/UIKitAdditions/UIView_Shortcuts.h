//
//  UIView_UIView_Shortcuts.h
//  qliq
//
//  Created by Aleksey Garbarev on 30.10.12.
//
//

#import <UIKit/UIKit.h>

@interface UIView (Shortcuts)

@property (nonatomic, readwrite) CGFloat x;
@property (nonatomic, readwrite) CGFloat y;
@property (nonatomic, readwrite) CGFloat width;
@property (nonatomic, readwrite) CGFloat height;

- (void) setFrameOriginX:(CGFloat) x;
- (void) setFrameOriginY:(CGFloat) y;
- (void) setFrameSizeWidth:(CGFloat) width;
- (void) setFrameSizeHeight:(CGFloat) height;

@end


static __inline__ UIViewAnimationOptions AnimationOptionsFromAnimationCurve(UIViewAnimationCurve curve)
{
    return curve << 16;
}

@implementation UIView(Shortcuts)

- (void) setX:(CGFloat) _x{
    [self setFrameOriginX:_x];
}

- (CGFloat) x{
    return self.frame.origin.x;
}

- (void) setWidth:(CGFloat) width{
    [self setFrameSizeWidth: width];
}

- (CGFloat) width{
    return self.frame.size.width;
}

- (void) setY:(CGFloat) y{
    [self setFrameOriginY: y];
}

- (CGFloat) y{
    return self.frame.origin.y;
}

- (void) setHeight:(CGFloat) height{
    [self setFrameSizeHeight: height];
}

- (CGFloat) height{
    return self.frame.size.height;
}



- (void) setFrameOriginX:(CGFloat) x{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (void) setFrameOriginY:(CGFloat) y{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (void) setFrameSizeWidth:(CGFloat) width{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}
- (void) setFrameSizeHeight:(CGFloat) height{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
    
}


@end