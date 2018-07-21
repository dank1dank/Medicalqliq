//
//  CareTeamMemberDetailsTabView.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/18/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "CareTeamMemberDetailsTabView.h"

@implementation CareTeamMemberDetailsTabView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        background = [[UIImageView alloc] init];
        background.image = [UIImage imageNamed:@"bg-toolbar"];
        [self addSubview:background];
        
        separator = [[UIImageView alloc] init];
        separator.image = [UIImage imageNamed:@"tab-separator.png"];
        [self addSubview:separator];
        
        editButton = [[UIButton alloc] init];
        [editButton setImage:[UIImage imageNamed:@"CareTeamMemberDetailsTabView_edit.png"] forState:UIControlStateNormal];
        [self addSubview:editButton];
        
        doneButton = [[UIButton alloc] init];
        [doneButton setImage:[UIImage imageNamed:@"CareTeamMemberDetailsTabView_done.png"] forState:UIControlStateNormal];        
        [self addSubview:doneButton];
        
        chatButton = [[UIButton alloc] init];
        [chatButton setImage:[UIImage imageNamed:@"btn-chat-on.png"] forState:UIControlStateNormal];
        [self addSubview:chatButton];
    }
    return self;
}


-(void) dealloc
{
    [background release];
    [separator release];
    [editButton release];
    [doneButton release];
    [chatButton release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    background.frame = CGRectMake(0.0,
                                  0.0,
                                  self.frame.size.width,
                                  self.frame.size.height);
    
    CGFloat chatButtonWidth = roundf(self.frame.size.width / 5.0);
    chatButton.frame = CGRectMake(self.frame.size.width - chatButtonWidth,
                                  0.0,
                                  chatButtonWidth,
                                  self.frame.size.height);
    
    separator.frame = CGRectMake(self.frame.size.width - chatButtonWidth - 2.0,
                                 0.0,
                                 2.0,
                                 self.frame.size.height);
    
    CGRect buttonsRect = CGRectMake(20.0,
                                    10.0,
                                    self.frame.size.width - chatButtonWidth - 2.0 - (20.0 * 2.0),
                                    self.frame.size.height - 10.0 * 2.0);
    
    editButton.frame = CGRectMake(buttonsRect.origin.x,
                                  buttonsRect.origin.y,
                                  roundf((buttonsRect.size.width / 2.0)) - 5.0,
                                  buttonsRect.size.height);
    
    doneButton.frame = CGRectMake(editButton.frame.origin.x + editButton.frame.size.width + 5.0,
                                  buttonsRect.origin.y,
                                  editButton.frame.size.width,
                                  buttonsRect.size.height);
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
