//
//  QliqLabel.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/9/12.
//
//

#import "QliqLabel.h"

@implementation QliqLabel


- (id) initWithFrame:(CGRect) frame style:(QliqLabelStyle) style{
    self = [super initWithFrame:frame];
    if (self) {
        
        switch (style) {
            case QliqLabelStyleNormal:
                self.font = [UIFont fontWithName:QliqFontName size:14];
                break;
            case QliqLabelStyleBold:
                self.font = [UIFont fontWithName:QliqFontNameBold size:14];
                break;
        }
        
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame style:QliqLabelStyleNormal];
}


- (void) setFontSize:(CGFloat) fontSize{
    [self setFont:[self.font fontWithSize:fontSize]];
}


@end
