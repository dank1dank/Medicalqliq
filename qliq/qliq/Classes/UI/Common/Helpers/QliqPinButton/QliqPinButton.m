//
//  QliqPinButton.m
//  qliq
//
//  Created by Valerii Lider on 16/11/15.
//
//

#import "QliqPinButton.h"

@implementation QliqPinButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/



- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        self.backgroundColor = RGBa(25.0f, 63.0f, 104.0f, 1.0f);
    }
    else {
        self.backgroundColor = [UIColor clearColor];
    }
    
    
    
}

@end
