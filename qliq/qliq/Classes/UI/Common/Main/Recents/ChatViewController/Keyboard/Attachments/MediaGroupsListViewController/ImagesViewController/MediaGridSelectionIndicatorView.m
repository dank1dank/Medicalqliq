//
//  ImagesSelectionIndicatorView.m
//  qliqConnect
//
//  Created by Paul Bar on 12/19/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "MediaGridSelectionIndicatorView.h"

#define CHECKMARK_SIZE 20.0

@implementation MediaGridSelectionIndicatorView

- (id)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor blackColor];
        backgroundView.alpha = 0.0;
        [self addSubview:backgroundView];
        
        selectedCheckbox = [[UIImageView alloc] init];
        selectedCheckbox.image = [UIImage imageNamed:@"white_round_checked.png"];
        selectedCheckbox.backgroundColor = [UIColor clearColor];
        selectedCheckbox.alpha = 0.0;
        [self addSubview:selectedCheckbox];
    }
    return self;
}

- (void) dealloc{
    
    [backgroundView removeFromSuperview], backgroundView = nil;
    [selectedCheckbox removeFromSuperview], selectedCheckbox = nil;
    

}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    if(self.frame.size.width < CHECKMARK_SIZE || self.frame.size.height < CHECKMARK_SIZE)
    {
        backgroundView.frame = self.frame;
        selectedCheckbox.frame = CGRectZero;
        return;
    }
    
    selectedCheckbox.frame = CGRectMake(0.0,
                                        self.frame.size.height - CHECKMARK_SIZE,
                                        CHECKMARK_SIZE,
                                        CHECKMARK_SIZE);
    
    backgroundView.frame = CGRectMake(0.0,
                                      0.0,
                                      self.frame.size.width,
                                      self.frame.size.height);
    
}

-(void) hide
{
    backgroundView.alpha = 0.0;
    selectedCheckbox.alpha = 0.0;
}

-(void) show
{   
    backgroundView.alpha = 0.5;
    selectedCheckbox.alpha = 1.0;
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
