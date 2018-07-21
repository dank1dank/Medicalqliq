//
//  LoginQliqTextField.m
//  qliq
//
//  Created by Valeriy Lider on 22.12.14.
//
//

#import "LoginQliqTextField.h"

@implementation LoginQliqTextField

- (void)drawPlaceholderInRect:(CGRect)rect
{
    UIColor *color = [UIColor lightGrayColor];
    
    if ([self.placeholder respondsToSelector:@selector(drawInRect:withAttributes:)])
    {
        NSDictionary *attributes = @{NSForegroundColorAttributeName: color,
                                     NSFontAttributeName: self.font};
        
        CGRect boundingRect = [self.placeholder boundingRectWithSize:rect.size
                                                             options:0
                                                          attributes:attributes context:nil];
        
        [self.placeholder drawAtPoint:CGPointMake(0, (rect.size.height/2)-boundingRect.size.height/2)
                       withAttributes:attributes];
    }
}

@end
