//
//  CallingView.m
//  qliq
//
//  Created by Paul Bar on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CallingView.h"

#define buttonWidth 290.0
#define buttonHeight 50.0
#define callingIconSize 155.0

@interface CallingView()
-(void) onEndCall;
@end

@implementation CallingView
@synthesize delegate;
@synthesize phoneLabel = phoneLabel;
@synthesize nameLabel = nameLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        // Initialization code
        nameLabel = [[[UILabel alloc] init] autorelease];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.font = [UIFont boldSystemFontOfSize:20.0];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        nameLabel.text = @"Dr. Krishna Kurapati";
        [self addSubview:nameLabel];
        
        phoneLabel = [[[UILabel alloc] init] autorelease];
        phoneLabel.backgroundColor = [UIColor clearColor];
        phoneLabel.textColor = [UIColor whiteColor];
        phoneLabel.font = [UIFont boldSystemFontOfSize:16.0];
        phoneLabel.textAlignment = NSTextAlignmentCenter;
        phoneLabel.text = @"(123) 321-123-33-22";
        [self addSubview:phoneLabel];
        
        callingImageView = [[[UIImageView alloc] init] autorelease];
        NSArray * images = [NSArray arrayWithObjects:
                            [UIImage imageNamed:@"calling1.png"], 
                            [UIImage imageNamed:@"calling2.png"],
                            [UIImage imageNamed:@"calling3.png"],
                            [UIImage imageNamed:@"calling4.png"], nil];
        callingImageView.animationImages = images;
        callingImageView.animationDuration = 3;
        [callingImageView startAnimating];
        [self addSubview:callingImageView];
        
        endCallButton = [[[UIButton alloc] init] autorelease];
        [endCallButton setBackgroundImage:[UIImage imageNamed:@"end_call_btn.png"] forState:UIControlStateNormal];
        [endCallButton setBackgroundImage:[UIImage imageNamed:@"end_call_btn_selected.png"] forState:UIControlStateHighlighted];
        [endCallButton addTarget:self action:@selector(onEndCall) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:endCallButton];
        
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

-(void) layoutSubviews
{
    [super layoutSubviews];
        
    CGFloat yOffset = 10.0;
    nameLabel.frame = CGRectMake(0.0, yOffset, self.frame.size.width, 20.0);
    
    yOffset += nameLabel.frame.size.height + 10.0;
    phoneLabel.frame = CGRectMake(0.0, yOffset, self.frame.size.width, 16.0);
    
    yOffset+=phoneLabel.frame.size.height + 30.0;
    
    callingImageView.frame = CGRectMake((self.frame.size.width-callingIconSize)/2.0,
                                        yOffset,
                                        callingIconSize,
                                        callingIconSize);
    
    CGRect btnFrame = CGRectMake((self.frame.size.width-buttonWidth)/2.0,
                                 self.frame.size.height-65.0,
                                 buttonWidth,
                                 buttonHeight);
    
    endCallButton.frame = btnFrame;

}


#pragma mark -
#pragma mark Private

-(void) onEndCall 
{
    [self.delegate endCallButtonPressed];
}

@end
