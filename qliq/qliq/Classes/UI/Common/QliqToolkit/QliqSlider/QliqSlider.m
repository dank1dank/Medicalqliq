//
//  QliqSlider.m
//  qliq
//
//  Created by Aleksey Garbarev on 11/2/12.
//
//

#import "QliqSlider.h"

@implementation QliqSlider

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
//        UIImage * backgroundImage = [UIImage imageNamed:@"Audio-Scrubber-BG"];
        [self setThumbImage:[UIImage imageNamed:@"qliqSwitchKnob"] forState:UIControlStateNormal];
//        [self setMinimumTrackImage:backgroundImage forState:UIControlStateNormal];
//        [self setMaximumTrackImage:backgroundImage forState:UIControlStateNormal];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
