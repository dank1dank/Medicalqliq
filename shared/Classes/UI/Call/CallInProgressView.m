//
//  CallInProgressView.m
//  qliq
//
//  Created by Paul Bar on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CallInProgressView.h"

#define buttonWidth 290.0
#define buttonHeight 50.0

@interface CallInProgressView()
-(void) onEndCall;
@end

@implementation CallInProgressView

@synthesize  delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        endCallButton = [[[UIButton alloc] init] autorelease];
        [endCallButton setBackgroundImage:[UIImage imageNamed:@"end_call_btn.png"] forState:UIControlStateNormal];
        [endCallButton setBackgroundImage:[UIImage imageNamed:@"end_call_btn_selected.png"] forState:UIControlStateHighlighted];
        [endCallButton addTarget:self action:@selector(onEndCall) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:endCallButton];

        cellPhoneBackground = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cells_background.png"]] autorelease];
        [self addSubview:cellPhoneBackground];
        
        cellPhoneView = [[[CellPhoneView alloc] initWithFrame:CGRectZero] autorelease];
        [self addSubview:cellPhoneView];
        
        self.backgroundColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];

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

-(void) dealloc
{
    [endCallButton release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    
    CGFloat cellPhoneWidth = CellButtonsWidth*3;
    CGFloat cellPhoneHeight = CellButtonsHeight*4;
    
    CGFloat viewsOffset = 30.0;

    cellPhoneView.frame = CGRectMake((self.frame.size.width-cellPhoneWidth)/2.0,
                                     viewsOffset,
                                     cellPhoneWidth,
                                     cellPhoneHeight);
    cellPhoneBackground.center = cellPhoneView.center;
    
    CGRect btnFrame = CGRectMake((self.frame.size.width-buttonWidth)/2.0, self.frame.size.height-65.0, buttonWidth, buttonHeight);
    
    endCallButton.frame = btnFrame;
    
}

#pragma mark -
#pragma mark Private

-(void) onEndCall
{
    [self.delegate endCallButtonPressed];
}

@end
