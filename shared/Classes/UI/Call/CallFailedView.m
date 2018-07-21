//
//  CallFailedView.m
//  qliq
//
//  Created by Paul Bar on 1/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CallFailedView.h"

#define buttonWidth 290.0
#define buttonHeight 50.0
#define callingIconSize 155.0

@interface CallFailedView()
-(void) onTryAgainCall;
@end

@implementation CallFailedView
@synthesize phoneLabel = phoneLabel;
@synthesize nameLabel = nameLabel;


@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        tryAgainButton = [[[UIButton alloc] init] autorelease];
        [tryAgainButton setBackgroundImage:[UIImage imageNamed:@"try_again_btn.png"] forState:UIControlStateNormal];
        [tryAgainButton setBackgroundImage:[UIImage imageNamed:@"try_again_btn_selected.png"] forState:UIControlStateHighlighted];
        [tryAgainButton addTarget:self action:@selector(onTryAgainCall) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:tryAgainButton];
        
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
        
        failedCallImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"failed_call.png"]] autorelease];
        [self addSubview:failedCallImageView];
        
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
    [super dealloc];
}

-(void) layoutSubviews
{
    CGFloat yOffset = 10.0;
    nameLabel.frame = CGRectMake(0.0, yOffset, self.frame.size.width, 20.0);
    
    yOffset += nameLabel.frame.size.height + 10.0;
    phoneLabel.frame = CGRectMake(0.0, yOffset, self.frame.size.width, 16.0);
    
    yOffset+=phoneLabel.frame.size.height + 30.0;
    
    failedCallImageView.frame = CGRectMake((self.frame.size.width-failedCallImageView.image.size.width)/2.0,
                                           yOffset,
                                           failedCallImageView.image.size.width,
                                           failedCallImageView.image.size.height);

    CGRect btnFrame = CGRectMake((self.frame.size.width-buttonWidth)/2.0,
                                 self.frame.size.height-65.0,
                                 buttonWidth,
                                 buttonHeight);
    
    tryAgainButton.frame = btnFrame;
}

#pragma mark -
#pragma mark Private

-(void) onTryAgainCall
{
    [self.delegate tryAgainButtonPressed];
}

@end
