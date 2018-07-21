//
//  MainTabView.m
//  CCiPhoneApp
//
//  Created by Marcin Zbijowski on 27/04/2011.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "MainTabView.h"
#import "Helper.h"
#import "ChatMessage.h"

@interface MainTabView (Private)

- (UILabel *)bottomLabelWithText:(NSString*)lblText frame:(CGRect)frame;
- (UIButton *)buttonWithNormalImage:(UIImage *)normalImg highlightImage:(UIImage *)highlightImg selectedImage:(UIImage *)selectImg frame:(CGRect)frame;
- (void)addSeparatorAtX:(CGFloat)posX;
- (void)chatBadgeValueChanged:(NSNotification *)notification;

@end


@implementation MainTabView

@synthesize meButton = _meButton;
@synthesize groupButton = _groupButton;
@synthesize roundsButton = _roundsButton;
@synthesize apptsButton = _apptsButton;
@synthesize chatButton = _chatButton;
@synthesize settingsButton = _settingsButton;

@synthesize meLabel = _meLabel;
@synthesize groupLabel = _groupLabel;
@synthesize roundsLabel = _roundsLabel;
@synthesize apptsLabel = _apptsLabel;

@synthesize badgeValue = _badgeValue;
@synthesize chatBadgeValue = _chatBadgeValue;
@synthesize canMeGroupMove = _canMeGroupMove;

- (id) initWithFrame: (CGRect) frame
{
    self = [super initWithFrame: frame];
    if (self) 
    {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-toolbar"]];
        _chatBadgeView = nil;
		
        int numberOfButtons = 5;
        int numberOfGroups = 2;
		
        UIImage* selectedBacgroundImage = [UIImage imageNamed: @"tab-selected-background.png"];
        int buttonWidth = selectedBacgroundImage.size.width;
        int buttonHeight = selectedBacgroundImage.size.height;
        int buttonsOffset = (CGRectGetWidth(frame) - buttonWidth * numberOfButtons) / (numberOfButtons - numberOfGroups + 1);
        int verticalOffset = (CGRectGetHeight(frame) - buttonHeight) / 2;
		
        UIImage* meGroupGroupBackgroundImage = [UIImage imageNamed: @"tab-grouped-background.png"];
        UIImageView* meGroupGroupBackground = [[[UIImageView alloc] initWithImage: meGroupGroupBackgroundImage] autorelease];
        meGroupGroupBackground.frame = CGRectMake(buttonsOffset, verticalOffset, meGroupGroupBackgroundImage.size.width, meGroupGroupBackgroundImage.size.height);
        
        meGroupSelectedBackground = [[[UIImageView alloc] initWithImage: selectedBacgroundImage] autorelease];
        meGroupSelectedBackground.frame = CGRectMake(buttonsOffset, verticalOffset, buttonWidth, buttonHeight);
        
        
        _meButton = [self buttonWithNormalImage: [UIImage imageNamed:@"btn-me-off"] 
                                 highlightImage: [UIImage imageNamed:@"btn-me-high"] 
                                  selectedImage: [UIImage imageNamed:@"btn-me-on"] 
                                          frame: CGRectMake(buttonsOffset, verticalOffset, buttonWidth, buttonHeight)];
        
        [_meButton addTarget: self
                      action: @selector(buttonPressed:)
            forControlEvents: UIControlEventTouchUpInside];
        _groupButton.tag = 0;
        
        _groupButton = [self buttonWithNormalImage: [UIImage imageNamed:@"btn-group-off"]
                                    highlightImage:[UIImage imageNamed:@"btn-group-high"]
                                     selectedImage:[UIImage imageNamed:@"btn-group-on"]
                                             frame:CGRectMake(CGRectGetMaxX(_meButton.frame), verticalOffset, buttonWidth, buttonHeight)];
        
        _groupButton.tag = 1;
		
        [_groupButton addTarget: self
                         action: @selector(buttonPressed:)
               forControlEvents: UIControlEventTouchUpInside];
        
        
        UIImageView* roundsApptsGroupBackground = [[[UIImageView alloc] initWithImage: meGroupGroupBackgroundImage] autorelease];
        roundsApptsGroupBackground.frame = CGRectMake(CGRectGetMaxX(_groupButton.frame) + buttonsOffset, verticalOffset, meGroupGroupBackgroundImage.size.width, meGroupGroupBackgroundImage.size.height);
        
        roundsApptsSelectedBackground = [[[UIImageView alloc] initWithImage: selectedBacgroundImage] autorelease];
        roundsApptsSelectedBackground.frame = CGRectMake(CGRectGetMaxX(_groupButton.frame) + buttonsOffset, verticalOffset, buttonWidth, buttonHeight);
        
        _roundsButton = [self buttonWithNormalImage:[UIImage imageNamed:@"btn-rounds-off"]
                                     highlightImage:[UIImage imageNamed:@"btn-rounds-high"]
                                      selectedImage:[UIImage imageNamed:@"btn-rounds-on"]
                                              frame:CGRectMake(CGRectGetMaxX(_groupButton.frame) + buttonsOffset, verticalOffset, buttonWidth, buttonHeight)];
        
        _roundsButton.tag = 2;
        
        [_roundsButton addTarget: self
						  action: @selector(buttonPressed:)
				forControlEvents: UIControlEventTouchUpInside];
        
		
        _apptsButton = [self buttonWithNormalImage:[UIImage imageNamed:@"btn-appts-off"]
                                    highlightImage:[UIImage imageNamed:@"btn-appts-high"]
                                     selectedImage:[UIImage imageNamed:@"btn-appts-on"]
                                             frame:CGRectMake(CGRectGetMaxX(_roundsButton.frame), verticalOffset, buttonWidth, buttonHeight)];
        
        _apptsButton.tag = 3;
        
        [_apptsButton addTarget: self
                         action: @selector(buttonPressed:)
               forControlEvents: UIControlEventTouchUpInside];
        
        
        _chatButton = [self buttonWithNormalImage:[UIImage imageNamed:@"btn-chat-on"]
                                   highlightImage:[UIImage imageNamed:@"btn-chat-high"]
                                    selectedImage:nil
                                            frame:CGRectMake(CGRectGetMaxX(_apptsButton.frame) + buttonsOffset, verticalOffset, buttonWidth, buttonHeight)];
		
        [self addSubview: meGroupGroupBackground];
        [self addSubview: meGroupSelectedBackground];
        [self addSubview: _meButton];
        [self addSubview: _groupButton];
        
        [self addSubview: roundsApptsGroupBackground];
        [self addSubview: roundsApptsSelectedBackground];
        [self addSubview:_roundsButton];
        [self addSubview:_apptsButton];
        [self addSubview:_chatButton];

//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(chatBadgeValueChanged:)
//                                                     name:ChatBadgeValueNotification object:nil]; 
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(removeNotificationObserver) 
                                                     name:@"RemoveNotifications" object:nil];
    }
	
    return self;
}
- (void)removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_meButton release];
    [_groupButton release];
    [_roundsButton release];
    [_apptsButton release];
    [_chatButton release];
    [_settingsButton release];
    
    [_meLabel release];
    [_groupLabel release];
    [_roundsLabel release];
    [_apptsLabel release];
    [_chatLabel release];
    [_settingsLabel release];
    [super dealloc];
}

#pragma mark -
#pragma mark Custom setters

- (void)setBadgeValue:(NSInteger)badgeValue {
    _badgeValue = badgeValue;
    if (_badgeValue == 0)
    {
        if (_badgeView != nil)
        {
            [_badgeView removeFromSuperview];
            _badgeView = nil;
        }
        return;
    }
    
    if (_badgeView != nil)
    {
        [_badgeView removeFromSuperview];
        _badgeView = nil;
    }
    
    _badgeView = [Helper badgeWithNumber: _badgeValue];
    
    CGRect frame = _badgeView.frame;
    frame.origin.x = _roundsButton.frame.origin.x + _roundsButton.frame.size.width - frame.size.width;
    frame.origin.y = 2;
    _badgeView.frame = frame;
    [self addSubview:_badgeView];
    [self setNeedsLayout];
}

- (void)setChatBadgeValue:(NSInteger)chatBadgeValue {
    
    if (_chatBadgeValue != chatBadgeValue)
    {
        _chatBadgeValue = chatBadgeValue;

        [_chatBadgeView removeFromSuperview];
        _chatBadgeView = nil;
        
        if (chatBadgeValue > 0)
        {
            _chatBadgeView = [Helper badgeWithNumber: chatBadgeValue];
            
            CGRect frame = _chatBadgeView.frame;
            frame.origin.x = _chatButton.frame.origin.x + _chatButton.frame.size.width - frame.size.width;
            frame.origin.y = 2;
            _chatBadgeView.frame = frame;
            [self addSubview: _chatBadgeView];
            [self setNeedsLayout];
        }
    }
}


#pragma mark -
#pragma mark Private

- (UILabel *)bottomLabelWithText:(NSString*)lblText frame:(CGRect)frame {
    UILabel *lbl = [[[UILabel alloc] initWithFrame:frame] autorelease];
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont boldSystemFontOfSize:11.0f];
    lbl.textAlignment = UITextAlignmentCenter;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.text = lblText;
    return lbl;
}

- (UIButton *)buttonWithNormalImage:(UIImage *)normalImg highlightImage:(UIImage *)highlightImg selectedImage:(UIImage *)selectImg frame:(CGRect)frame {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:normalImg forState:UIControlStateNormal];
	//    [btn setImage:highlightImg forState:UIControlStateHighlighted];
    [btn setImage:selectImg forState:UIControlStateSelected];
    btn.frame = frame;
    return btn;
}

- (void)addSeparatorAtX:(CGFloat)posX {
    UIImageView *separator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tab-separator"]];
    CGRect frame = separator.frame;
    frame.origin.x = posX;
    separator.frame = frame;
    [self addSubview:separator];
    [separator release];
}


- (void) buttonPressed: (UIButton*) sender
{
    UIView* selectedView;
    if (sender.tag > 1)
    {
        selectedView = roundsApptsSelectedBackground;
    }
    else
    {
        selectedView = meGroupSelectedBackground;
    }
	
    
    [UIView beginAnimations: nil context: NULL];
    
    CGRect selectedViewFrame = selectedView.frame;
	if (sender.tag == 0)
	{
		selectedViewFrame.origin.x = _meButton.frame.origin.x;       
	}
	else if (sender.tag == 1)
	{
		selectedViewFrame.origin.x = _groupButton.frame.origin.x;       
	}else if (sender.tag == 2)
    {
        selectedViewFrame.origin.x = _roundsButton.frame.origin.x;       
    }
    else if (sender.tag == 3)
    {
        selectedViewFrame.origin.x = _apptsButton.frame.origin.x;       
    }
    
    
    
    selectedView.frame = selectedViewFrame;
	
    [UIView commitAnimations];    
    
}

- (void) chatBadgeValueChanged:(NSNotification *)notification
{
    [self setChatBadgeValue:[[notification object] integerValue]];
}

@end
