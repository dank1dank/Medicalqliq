//
//  NavBarInCallStateView.m
//  qliq
//
//  Created by Paul Bar on 3/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NavBarInCallStateView.h"
#import <QuartzCore/QuartzCore.h>

#define TAPABLE_AREA_WIDTH 50.0

@interface NavBarInCallStateView(Private)

- (void)tapAction:(UITapGestureRecognizer*)sender;

@end

@implementation NavBarInCallStateView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        bg = [[UIView alloc] init];
        bg.backgroundColor = [UIColor blackColor];
        bg.alpha = 0.5;
        [self addSubview:bg];
        
        label = [[UILabel alloc] init];
        label.font = [UIFont boldSystemFontOfSize:12.0];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.text = @"Touch to return to call";
        [self addSubview:label];
        
        NSMutableArray *mutableColors = [[NSMutableArray alloc] init];
        int steps = 5;
        
        UIColor *viewColor = [UIColor colorWithRed:(211.0 / 255.0) green:(85.0/255.0) blue:(44.0/255.0) alpha:1.0];
        CGFloat R,G,B;
        const CGFloat *colorComponents = CGColorGetComponents([viewColor CGColor]);
        R = colorComponents[0];
        G = colorComponents[1];
        B = colorComponents[2];
        CGFloat currentAlpha = 0.2;
        
        for(int i = 0; i< steps; i++)
        {
            UIColor *color = [UIColor colorWithRed:R green:G blue:B alpha:currentAlpha];
            [mutableColors addObject:(id)[color CGColor]];
            currentAlpha += 1.0 / steps;
        }
        
        for(int i = 0; i< steps; i++)
        {
            UIColor *color = [UIColor colorWithRed:R green:G blue:B alpha:currentAlpha];
            [mutableColors addObject:(id)[color CGColor]];
            currentAlpha -= 1.0 / steps;
        }
        
        gradient = [CAGradientLayer layer];
        gradient.colors = [NSArray arrayWithArray:mutableColors];
        [mutableColors release];
        [gradient setStartPoint:CGPointMake(0.0, 0.5)];
        [gradient setEndPoint:CGPointMake(1.0, 0.5)];
        [bg.layer insertSublayer:gradient atIndex:0];
        
        tapGestureRecognizer = [[UITapGestureRecognizer alloc] init];
        [tapGestureRecognizer addTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tapGestureRecognizer];
    }
    return self;
}

-(void) dealloc
{
    [tapGestureRecognizer release];
    [gradient release];
    [bg release];
    [label release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    bg.frame = CGRectMake(0.0,
                          0.0,
                          self.frame.size.width,
                          self.frame.size.height);
    
    label.frame = CGRectMake(0.0,
                             0.0,
                             self.frame.size.width,
                             self.frame.size.height);
    
    gradient.frame = bg.bounds;
}

-(void) startPulsing
{
    CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    pulseAnimation.duration = 2.0;
    pulseAnimation.repeatCount = HUGE_VALF;
    pulseAnimation.autoreverses = YES;
    pulseAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    pulseAnimation.toValue = [NSNumber numberWithFloat:0.5];
    [gradient addAnimation:pulseAnimation forKey:@"pulse"];
}

-(void) stopPulsing
{
    [gradient removeAnimationForKey:@"pulse"];
    gradient.opacity = 1.0;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
#pragma mark -
#pragma mark Private

-(void) tapAction:(UITapGestureRecognizer *)sender
{
    CGPoint touchPoint = [sender locationInView:self];
    
    CGFloat xCenter = roundf(self.frame.size.width / 2.0);
    CGFloat areaHalfWidth = roundf(TAPABLE_AREA_WIDTH / 2.0);
    
    if(touchPoint.x > xCenter - areaHalfWidth 
       && touchPoint.x < xCenter + areaHalfWidth)
    {
        [self.delegate inCallStateViewPressed];
    }
}

@end
