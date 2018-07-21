//
//  NavigationBarChattingWithView.m
//  qliqConnect
//
//  Created by Paul Bar on 12/19/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "NavigationBarChattingWithView.h"
#define BUTTON_SIZE 20.0
#define VIEWS_SPACE 10.0

@interface NavigationBarChattingWithView()

@end

@implementation NavigationBarChattingWithView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        recipientNameLabel = [[UILabel alloc] init];
        recipientNameLabel.backgroundColor = [UIColor clearColor];
        recipientNameLabel.font = [UIFont boldSystemFontOfSize:14.0];
        recipientNameLabel.adjustsFontSizeToFitWidth = NO;
        recipientNameLabel.textColor = [UIColor whiteColor];
        recipientNameLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:recipientNameLabel];
        
        regardingTextLabel = [[UILabel alloc] init];
        regardingTextLabel.backgroundColor = [UIColor clearColor];
        regardingTextLabel.font = [UIFont systemFontOfSize:14.0];
        //regardingTextLabel.adjustsFontSizeToFitWidth = YES;
        regardingTextLabel.textColor = [UIColor whiteColor];
        regardingTextLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:regardingTextLabel];

    }
    return self;
}

- (void)dealloc 
{
    [regardingTextLabel release];
    [recipientNameLabel release];
    [super dealloc];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    if(self.frame.size.width < BUTTON_SIZE)
    {
        recipientNameLabel.frame = CGRectZero;
        regardingTextLabel.frame = CGRectZero;
        return;
    }
    CGFloat xRightOffset = 0.0;
    
    xRightOffset += VIEWS_SPACE / 2.0;
    
    CGSize size = [recipientNameLabel.text sizeWithAttributes:@{NSFontAttributeName : recipientNameLabel.font}];
    CGSize labelSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
    
    CGFloat maxLabelWidth = self.frame.size.width - xRightOffset - VIEWS_SPACE;
 
    labelSize.width = maxLabelWidth;

    if([self.regardingText length] == 0)
    {
        recipientNameLabel.frame = CGRectMake(VIEWS_SPACE,
                                              roundf((self.frame.size.height) / 2.0 - (labelSize.height / 2.0)),
                                              labelSize.width,
                                              labelSize.height);
    }
    else
    {
        recipientNameLabel.frame = CGRectMake(0.0,
                                              VIEWS_SPACE / 2.0,
                                              labelSize.width,
                                              labelSize.height);
        
        CGFloat maxLabelHeight = self.frame.size.height - recipientNameLabel.frame.size.height;
        
        size = [regardingTextLabel.text sizeWithAttributes:@{NSFontAttributeName : regardingTextLabel.font}];
        labelSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
        
        
        labelSize.width = maxLabelWidth;
        if(labelSize.height > maxLabelHeight)
        {
            labelSize.height = maxLabelHeight;
        }
        
        regardingTextLabel.frame = CGRectMake(0.0,
                                              recipientNameLabel.frame.origin.y + recipientNameLabel.frame.size.height,
                                              labelSize.width,
                                              labelSize.height);
        
    }
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void) setDisclosureButtonOpen:(BOOL)open animaged:(BOOL)animated
{
}

#pragma mark Properties 

-(void) setRecipientName:(NSString *)recipientName
{
    recipientNameLabel.text = recipientName;
}
-(NSString*) recipientName
{
    return recipientNameLabel.text;
}

-(void) setRegardingText:(NSString *)regardingText
{
    NSString *resultString;
    resultString = regardingText;
    regardingTextLabel.text = resultString;
    [self setNeedsLayout];
}

-(NSString*) regardingText
{
    return regardingTextLabel.text;
}

#pragma mark -
#pragma mark Private

@end
