//
//  QliqSwitch.m
//  qliq
//
//  Created by Aleksey Garbarev on 17/10/12.
//
//

#import "QliqSwitch.h"


@implementation QliqSwitch{
	UILabel *onText;
	UILabel *offText;
	
	UIImage *onImage;
	UIImage *offImage;
}

@synthesize context;

- (void)initCommon{
    
	[super initCommon];

    knobImagePressed =
    knobImage = [UIImage imageNamed:@"qliqSwitchKnob"];

    knobImageOffset.height = 0;
    knobWidth = 30;
    endcapWidth = 0;
    
    knobEndcapOffset = CGSizeMake(3, 0);
    
    onText = [UILabel new];
    onText.text = @"On";
    onText.textColor = [UIColor whiteColor];
    onText.font = [UIFont boldSystemFontOfSize:14];
    
    offText = [UILabel new];
    offText.text = @"Off";
    offText.textColor = [UIColor whiteColor];
    offText.font = [UIFont boldSystemFontOfSize:14];
    
    offText.backgroundColor = onText.backgroundColor = [UIColor clearColor];
    
    onText.shadowColor = offText.shadowColor = [UIColor blackColor];
    onText.shadowOffset = offText.shadowOffset = CGSizeMake(0, 0.5);
    
    [overlayView addSubview:offText];
    [overlayView addSubview:onText];
    
    [onText sizeToFit];
    [offText sizeToFit];
}

- (void)regenerateImages{
    sliderOff = [[UIImage imageNamed:@"qliqSwitchOn"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
    sliderOn = [[UIImage imageNamed:@"qliqSwitchOff"] stretchableImageWithLeftCapWidth:10 topCapHeight:0];
}


- (BOOL)isOn{
    return ![super isOn];
}

//- (void)setOn:(BOOL)on{
//    [super setOn:on];
//}

- (void)setOn:(BOOL)aBool animated:(BOOL)animated{
    [super setOn:!aBool animated:animated];
}

- (void)drawUnderlayersInRect:(CGRect)aRect withOffset:(float)offset inTrackWidth:(float)trackWidth{
    
    CGRect offFrame = offText.frame;
    offFrame.origin.x = 10 + roundf(offset - knobWidth - (self.bounds.size.width - knobWidth - offText.bounds.size.width)/2);
    offFrame.origin.y = roundf((self.bounds.size.height - offText.bounds.size.height)/2)-2;
    offText.frame = offFrame;
    
    CGRect onFrame = onText.frame;
    onFrame.origin.x = roundf(offset + knobWidth + (self.bounds.size.width - knobWidth - onText.bounds.size.width)/2);
    onFrame.origin.y = roundf((self.bounds.size.height - onText.bounds.size.height)/2)-2;
    onText.frame = onFrame;
    
}

@end
