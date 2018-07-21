//
//  CallView.m
//  qliq
//
//  Created by Paul Bar on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CallView.h"
#import "Contact.h"

#define TAB_VIEW_HEIGHT 55.0


@interface CallView()

-(void) answerButtonPressed;
-(void) declineButtonPressed;
-(void) forwardButtonPressed;
-(void) declineWithMessageButtonPressed;
-(void) endCallButtonPressed;
-(void) tryAgainButtonPressed;

@end

@implementation CallView
@synthesize table;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        incomingCallView = [[IncomingCallView alloc] init];
        incomingCallView.delegate = self;
        [incomingCallView setHidden:YES];
        [self addSubview:incomingCallView];
        
        callingView = [[CallingView alloc] init];
        callingView.delegate = self;
        [callingView setHidden:YES];
        [self addSubview:callingView];
        
        callFailedView = [[CallFailedView alloc] init];
        callFailedView.delegate = self;
        [callFailedView setHidden:YES];
        [self addSubview:callFailedView];
        
        callInProgressView = [[CallInProgressView alloc] init];
        callInProgressView.delegate = self;
        [callInProgressView setHidden:YES];
        [self addSubview:callInProgressView];
        
        callViews = [[NSArray arrayWithObjects:incomingCallView, 
                      callingView,
                      callFailedView,
                      callInProgressView,
                      nil] retain];
        
        table = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 480.0, 320.0, 0.0)];
        table.showsVerticalScrollIndicator = NO;
        table.backgroundColor = [UIColor whiteColor];
        table.rowHeight = 40.0;
        table.bounces = NO;
        [self addSubview:table];
        
        self.backgroundColor = [UIColor colorWithWhite:0.2196 alpha:1.0f];
    }
    return self;
}


-(void) dealloc
{
    [callViews release];
    [incomingCallView release];
    [callingView release];
    [callFailedView release];
    [callInProgressView release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
 
    
    CGRect viewsFrame = CGRectMake(0.0,
                                   0.0,
                                   self.frame.size.width,
                                   self.frame.size.height);
    
    incomingCallView.frame = viewsFrame;
    callingView.frame = viewsFrame;
    callFailedView.frame = viewsFrame;
    callInProgressView.frame = viewsFrame;
}


-(void) presentState:(CallViewState)state
{
    for(UIView *v in callViews)
    {
        v.hidden = YES;
    }
    
    UIView *viewForState = [callViews objectAtIndex:state];
    viewForState.hidden = NO;
}

-(void) showTable
{
    [UIView beginAnimations:@"ShowTable" context:nil];
    table.frame = CGRectMake(0.0,
                             self.frame.size.height - 250.0,
                             self.frame.size.width,
                             250.0);
    [UIView commitAnimations];
}

-(void) hideTable
{
    [UIView beginAnimations:@"HideTable" context:nil];
    table.frame = CGRectMake(0.0,
                             self.frame.size.height,
                             self.frame.size.width,
                             0.0);
    [UIView commitAnimations];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void) updateRecipientName:(Contact *)contact
{
    incomingCallView.nameLabel.text = [contact nameDescription];
    callingView.nameLabel.text = [contact nameDescription];
    callFailedView.nameLabel.text = [contact nameDescription];
    
    incomingCallView.phoneLabel.text = [contact email];
    callingView.phoneLabel.text = [contact email];
    callFailedView.phoneLabel.text = [contact email];
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

-(void) forwardButtonPressed
{
    [self.delegate forwardButtonPressed];
}

-(void) declineWithMessageButtonPressed
{
    [self.delegate declineWithMessageButtonPressed];
}

-(void) endCallButtonPressed
{
    [self.delegate endCallButtonPressed];
}

-(void) tryAgainButtonPressed
{
    [self.delegate tryAgainButtonPressed];
}


@end
