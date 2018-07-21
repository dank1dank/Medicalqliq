//
//  ChatBackgroundView.m
//  qliq
//
//  Created by Paul Bar on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ChatBackgroundView.h"
#import "ChatView.h"

@implementation ChatBackgroundView
@synthesize chatView = chatView;
@synthesize keyboardHeight;

- (void) initialization{
    chatView = [[ChatView alloc] init];
    [self addSubview:chatView];
    [chatView release];
}

- (id) initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self){
        [self initialization];
        
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self){
        [self initialization];
    }
    return self;
}

-(void) dealloc
{
    
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
//    chatView.frame = CGRectMake(0.0,
//                                - keyboardHeight,
//                                self.frame.size.width,
//                                self.frame.size.height);
    

}




-(void) setKeyboardHeight:(CGFloat)_keyboardHeight
{
    keyboardHeight = _keyboardHeight;
    [self layoutSubviews];
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
