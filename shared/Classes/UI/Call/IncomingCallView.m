//
//  IncomingCallView.m
//  qliq
//
//  Created by Paul Bar on 1/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IncomingCallView.h"
#import <QuartzCore/QuartzCore.h>
#define TAB_VIEW_HEIGHT 55.0
#define BUTTONS_HEIGHT 44.0

@interface IncomingCallView()

-(void) answerButtonPressed;
-(void) declineButtonPressed;
-(void) declineWithMessageButtonPressed;
-(void) forwardButtonPressed;

@end

@implementation IncomingCallView
@synthesize delegate;
@synthesize phoneLabel = phoneLabel;
@synthesize nameLabel = nameLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code

        nameLabel = [[UILabel alloc] init];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.textColor = [UIColor whiteColor];
        nameLabel.font = [UIFont boldSystemFontOfSize:20.0];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:nameLabel];
        
        phoneLabel = [[UILabel alloc] init];
        phoneLabel.backgroundColor = [UIColor clearColor];
        phoneLabel.textColor = [UIColor whiteColor];
        phoneLabel.font = [UIFont boldSystemFontOfSize:16.0];
        phoneLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:phoneLabel];
        
        answerButton = [[UIButton alloc] init];
        [answerButton addTarget:self action:@selector(answerButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [answerButton setImage:[UIImage imageNamed:@"Answer-Button-Short.png"] forState:UIControlStateNormal];
        [answerButton setImage:[UIImage imageNamed:@"Answer-Button-Short-OnTap.png"] forState:UIControlStateHighlighted];
        [self addSubview:answerButton];
        
        declineButton = [[UIButton alloc] init];
        [declineButton addTarget:self action:@selector(declineButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [declineButton setImage:[UIImage imageNamed:@"Decline-Button-Short.png"] forState:UIControlStateNormal];
        [declineButton setImage:[UIImage imageNamed:@"Decline-Button-Short-OnTap.png"] forState:UIControlStateHighlighted];
        [self addSubview:declineButton];
        
		
        forwardButton = [[UIButton alloc] init];
        [forwardButton addTarget:self action:@selector(forwardButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [forwardButton setImage:[UIImage imageNamed:@"Forward-Short-Buttons.png"] forState:UIControlStateNormal];
        [forwardButton setImage:[UIImage imageNamed:@"Forward-Short-Buttons-OnTap.png"] forState:UIControlStateHighlighted];
        //[self addSubview:forwardButton];
        
        declineWithMessageButton = [[UIButton alloc] init];
        [declineWithMessageButton addTarget:self action:@selector(declineWithMessageButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [declineWithMessageButton setImage:[UIImage imageNamed:@"Decline-w-Message-Short-Button.png"] forState:UIControlStateNormal];
        [declineWithMessageButton setImage:[UIImage imageNamed:@"Decline-w-Message-Short-Button-OnTap.png"] forState:UIControlStateHighlighted];
        //[self addSubview:declineWithMessageButton];
        
        self.backgroundColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
    }
    return self;
}


-(void) dealloc
{
    [forwardButton release];
    [declineWithMessageButton release];
    [declineButton release];
    [answerButton release];
    [phoneLabel release];
    [nameLabel release];
    //[tabView release];
    [super dealloc];
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
    
    CGFloat yOffset = 20.0;
    nameLabel.frame = CGRectMake(0.0,
                                 yOffset,
                                 self.frame.size.width,
                                 20.0);
    
    yOffset += nameLabel.frame.size.height + 10.0;
    
    phoneLabel.frame = CGRectMake(0.0,
                                  yOffset,
                                  self.frame.size.width,
                                  16.0);
    
    yOffset+=phoneLabel.frame.size.height;
    
    yOffset += 20.0;
    
    CGFloat buttonsWidth = 135.0;
    
    answerButton.frame = CGRectMake(20.0,
                                    yOffset,
                                    buttonsWidth,
                                    BUTTONS_HEIGHT);
    
    declineButton.frame = CGRectMake(answerButton.frame.origin.x + answerButton.frame.size.width + 10.0,
                                     yOffset,
                                     buttonsWidth,
                                     BUTTONS_HEIGHT);
    
    yOffset += BUTTONS_HEIGHT;
    yOffset += 20.0;
    
    forwardButton.frame = CGRectMake(20.0,
                                     yOffset,
                                     buttonsWidth,
                                     BUTTONS_HEIGHT);
    
    declineWithMessageButton.frame =  CGRectMake(forwardButton.frame.origin.x + forwardButton.frame.size.width + 10.0,
                                                 yOffset,
                                                 buttonsWidth,
                                                 BUTTONS_HEIGHT);
}

#pragma mark -
#pragma mark Private

-(void) answerButtonPressed
{
    [self.delegate answerButtonPressed];
}

-(void) declineButtonPressed
{
    [self.delegate declineButtonPressed];
}

-(void) declineWithMessageButtonPressed
{
    [self.delegate declineWithMessageButtonPressed];
}

-(void) forwardButtonPressed
{
    [self.delegate forwardButtonPressed];   
}

@end
