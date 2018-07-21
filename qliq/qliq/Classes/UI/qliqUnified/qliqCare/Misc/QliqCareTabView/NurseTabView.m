//
//  NurseTabView.m
//  CCiPhoneApp
//
//  Created by Paul Bar on 11/11/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "NurseTabView.h"

#define SEPARATOR_WIDTH 2.0
#define NUMBER_OF_SECTIONS 5.0
#define GROUP_BUTTON_HEIGHT 44.0
#define GROUP_BUTTON_WIDTH 60.0

@interface NurseTabView()

-(void) highlightButton:(UIButton*)button;
-(void) patientsButtonPressed:(UIButton*)sender;
-(void) roomsButtonPressed:(UIButton*)sender;
-(void) nurseButtonPressed:(UIButton*)sender;
-(void) chatButtonPressd: (UIButton*)sender;
-(void) alertsButtonPressed: (UIButton*)sender;

@end


@implementation NurseTabView

@synthesize delegate = delegate_;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-toolbar"]];
        
        buttonGroupBackground = [[UIImageView alloc] initWithFrame:CGRectZero];
        buttonGroupBackground.image = [UIImage imageNamed:@"tab-grouped-background.png"];
        [self addSubview:buttonGroupBackground];
        
        buttonHighlightingView = [[UIImageView alloc] initWithFrame:CGRectZero];
        buttonHighlightingView.image = [UIImage imageNamed:@"tab-selected-background.png"];
        [self addSubview:buttonHighlightingView];
        
        patientsButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [patientsButton setImage:[UIImage imageNamed:@"patients_blue.png"] forState:UIControlStateNormal];
        [patientsButton setImage:[UIImage imageNamed:@"patients_dark.png"] forState:UIControlStateHighlighted];
        [patientsButton addTarget:self action:@selector(patientsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:patientsButton];
        
        roomsButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [roomsButton setImage:[UIImage imageNamed:@"rooms_blue.png"] forState:UIControlStateNormal];
        [roomsButton setImage:[UIImage imageNamed:@"rooms_dark.png"] forState:UIControlStateHighlighted];
        [roomsButton addTarget:self action:@selector(roomsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:roomsButton];
        
        nurseButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [nurseButton setImage:[UIImage imageNamed:@"nurse_blue.png"] forState:UIControlStateNormal];
        [nurseButton setImage:[UIImage imageNamed:@"nurse_dark.png"] forState:UIControlStateHighlighted];
        [nurseButton addTarget:self action:@selector(nurseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:nurseButton];
        
        buttonGroupAlertSeparator = [[UIImageView alloc] initWithFrame:CGRectZero];
        buttonGroupAlertSeparator.image = [UIImage imageNamed:@"tab-separator.png"];
        [self addSubview:buttonGroupAlertSeparator];
        
        alertButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [alertButton setImage:[UIImage imageNamed:@"alert.png"] forState:UIControlStateNormal];
        [alertButton addTarget:self action:@selector(alertsButtonPressed:) forControlEvents: UIControlEventTouchUpInside];
        [self addSubview:alertButton];
        
        alertChatSeparator = [[UIImageView alloc] initWithFrame:CGRectZero];
        alertChatSeparator.image = [UIImage imageNamed:@"tab-separator.png"];
        [self addSubview:alertChatSeparator];
        
        chatButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [chatButton setImage:[UIImage imageNamed:@"btn-chat-on.png"] forState:UIControlStateNormal];
        [chatButton addTarget:self action:@selector(chatButtonPressd:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:chatButton];
        
        initialSelectedItem = 0;
    }
    return self;
}

-(id) initWithSelectedItem:(NSInteger)selectedItemIndex
{
    self = [self initWithFrame:CGRectZero];
    if(self)
    {
        initialSelectedItem = selectedItemIndex;
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
    [buttonHighlightingView release];
    [roomsButton release];
    [patientsButton release];
    [buttonGroupBackground release];
    [chatButton release];
    [alertButton release];
    [buttonGroupAlertSeparator release];
    [alertChatSeparator release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    CGFloat sectionWidth = roundf(self.frame.size.width / NUMBER_OF_SECTIONS);
    CGFloat xOffset = 0.0;
    
    CGFloat buttonGroupOriginX = roundf(
                                        (((sectionWidth * 3.0) - (2.0 * SEPARATOR_WIDTH)) / 2.0)
                                        - ((GROUP_BUTTON_WIDTH * 3.0) / 2.0)
                                        );
    CGFloat buttonGroupOriginY = roundf((self.frame.size.height / 2.0) - (GROUP_BUTTON_HEIGHT / 2.0));
    
    
    buttonGroupBackground.frame = CGRectMake(buttonGroupOriginX,
                                             buttonGroupOriginY,
                                             GROUP_BUTTON_WIDTH * 3.0,
                                             GROUP_BUTTON_HEIGHT);
    
    if(CGRectEqualToRect(buttonHighlightingView.frame, CGRectZero))
    {
        if(initialSelectedItem < 0 || initialSelectedItem > 2)
        {
            initialSelectedItem = 0;
        }
        buttonHighlightingView.frame = CGRectMake(buttonGroupOriginX + GROUP_BUTTON_WIDTH * initialSelectedItem,
                                                  buttonGroupOriginY,
                                                  GROUP_BUTTON_WIDTH,
                                                  GROUP_BUTTON_HEIGHT);
    }
    
    patientsButton.frame = CGRectMake(buttonGroupOriginX,
                                      buttonGroupOriginY,
                                      GROUP_BUTTON_WIDTH,
                                      GROUP_BUTTON_HEIGHT);
    
    roomsButton.frame = CGRectMake(buttonGroupOriginX + GROUP_BUTTON_WIDTH,
                                   buttonGroupOriginY,
                                   GROUP_BUTTON_WIDTH,
                                   GROUP_BUTTON_HEIGHT);
    
    nurseButton.frame = CGRectMake(buttonGroupOriginX + GROUP_BUTTON_WIDTH * 2.0,
                                   buttonGroupOriginY,
                                   GROUP_BUTTON_WIDTH,
                                   GROUP_BUTTON_HEIGHT);
    
    xOffset = (sectionWidth * 3.0) - (2.0 * SEPARATOR_WIDTH);
    buttonGroupAlertSeparator.frame = CGRectMake(xOffset,
                                                 0.0,
                                                 SEPARATOR_WIDTH,
                                                 self.frame.size.height);
    xOffset += buttonGroupAlertSeparator.frame.size.width;
    
    
    alertButton.frame = CGRectMake(xOffset,
                                   0.0,
                                   sectionWidth - SEPARATOR_WIDTH,
                                   self.frame.size.height);
    xOffset += alertButton.frame.size.width;
    
    alertChatSeparator.frame = CGRectMake(xOffset,
                                          0.0,
                                          SEPARATOR_WIDTH,
                                          self.frame.size.width);
    xOffset += alertChatSeparator.frame.size.width;
    
    chatButton.frame = CGRectMake(xOffset,
                                  0.0,
                                  sectionWidth,
                                  self.frame.size.height);
}

#pragma mark -
#pragma mark Private methods

-(void) highlightButton:(UIButton *)button
{
    [UIView beginAnimations:nil context:nil];
    buttonHighlightingView.center = button.center;
    [UIView commitAnimations];
}

-(void) patientsButtonPressed:(UIButton *)sender
{
    [self highlightButton:sender];
    if([self.delegate respondsToSelector:@selector(patientsButtonPressed)])
    {
        [self.delegate patientsButtonPressed];
    }
    
}

-(void) roomsButtonPressed:(UIButton *)sender
{
    [self highlightButton:sender];
    if([self.delegate respondsToSelector:@selector(roomsButtonPressed)])
    {
        [self.delegate roomsButtonPressed];
    }
}

-(void) nurseButtonPressed:(UIButton *)sender
{
    [self highlightButton:sender];
    if([self.delegate respondsToSelector:@selector(nurseButtonPressed)])
    {
        [self.delegate nurseButtonPressed];
    }
}


-(void) chatButtonPressd:(UIButton *)sender
{
    if([self.delegate respondsToSelector:@selector(chatButtonPressed)])
    {
        [self.delegate chatButtonPressed];
    }
}
 
-(void) alertsButtonPressed:(UIButton *)sender
{
    if([self.delegate respondsToSelector:@selector(alertButtonPressed)])
    {
        [self.delegate alertButtonPressed];
    }
}

@end
