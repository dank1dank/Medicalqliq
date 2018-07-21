//
//  AckView.m
//  qliqConnect
//
//  Created by Paul Bar on 11/29/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "AckView.h"
#import "ChatMessage.h"

@interface AckView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;

- (void)tapEvent:(UITapGestureRecognizer*)sender;

@end

@implementation AckView

@synthesize state = state_;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        
        self.tapRecognizer = [[UITapGestureRecognizer alloc] init];
        [self.tapRecognizer addTarget:self action:@selector(tapEvent:)];
        [self addGestureRecognizer:self.tapRecognizer];
        
        self.totalRecipientCount = 0;
        self.ackedRecipientCount = 0;
        
        
        //        self.state = AckViewStateTapToAck;
    }
    return self;
}

#pragma mark - Setter

- (void)setState:(AckViewState)state
{
    NSString *labelText = @"";
    UIImage *checkmarkImage = nil;
    
    switch (state)
    {
        case AckViewStateAckNeeded: {
            
            labelText       = QliqLocalizedString(@"1920-StatusNotAcknowledged");
            checkmarkImage  = nil;
            //            self.alpha = 0.4f;
            self.backgroundImageView.image = [UIImage imageNamed:@"ackViewBackground.png"];
            
            if (self.totalRecipientCount > 1 && self.ackedRecipientCount > 0)
            {
                labelText = QliqFormatLocalizedString2(@"1941-StatusAcknowledgedBy", (long)self.ackedRecipientCount, (long)self.totalRecipientCount);
            }
            
            break;
        }
            
        case AckViewStateAckGot: {
            
            labelText       = QliqLocalizedString(@"1942-StatusAcknowledged");
            checkmarkImage  = [UIImage imageNamed:@"CheckmarkAck"];
            //            self.alpha = 1.f;
            self.backgroundImageView.image = [UIImage imageNamed:@"ackViewBackgroundChecked.png"];
            
            //            if (state_ == AckViewStateAckNeeded)
            //            {
            //                [self performSelector:@selector(replaceAckView) withObject:nil afterDelay:3.0];
            //                [self performSelector:@selector(replaceAckView)];
            //            }
            
            break;
        }
            
        case AckViewStateTapToAck: {
            
            labelText       = QliqLocalizedString(@"1943-StatusTapToAcknowledge");
            checkmarkImage  = nil;
            //            self.alpha = 0.4f;
            self.backgroundImageView.image = [UIImage imageNamed:@"ackViewBackground.png"];
            
            break;
        }
            
        case AckViewStateAckGiven: {
            
            labelText       = QliqLocalizedString(@"1942-StatusAcknowledged");
            checkmarkImage  = [UIImage imageNamed:@"CheckmarkAck"];
            //            self.alpha = 1.f;
            self.backgroundImageView.image = [UIImage imageNamed:@"ackViewBackgroundChecked.png"];
            
            if (state_ == AckViewStateTapToAck)
            {
                [self performSelector:@selector(replaceAckView) withObject:nil afterDelay:3.0];
                //                [self performSelector:@selector(replaceAckView)];
            }
            
            break;
        }
        default: break;
    }
    
    self.ackTitleLabel.text = labelText;
    //    self.checkmarkImageView.image = checkmarkImage;
    state_ = state;
    
    [self setNeedsLayout];
}

#pragma mark - Public

- (void)setAckViewWithState:(AckViewState)state isMyMessage:(BOOL)isMyMessage isHaveAttachment:(BOOL)isMessageHaveAttachment
{
    NSString *labelText = @"";
    UIImage *checkmarkImage = nil;
    
    //    UIImage *notChekedBlueImage = [UIImage imageNamed:@"ConversationUnChecked"];
    UIImage *notChekedImage     = [UIImage imageNamed:@"ConversationUnCheckedWhite"];
    UIImage *chekedImageBlue    = [UIImage imageNamed:@"ConversationChecked"];
    UIImage *chekedImage        = [UIImage imageNamed:@"ConversationCheckedWhite"];
    
    UIColor *whiteColor = [UIColor whiteColor];
    UIColor *blueColor = RGBa(24, 122, 181, 1);
    UIColor *orangeColor = [UIColor orangeColor];//RGBa(203, 84, 51, 1);
    
    //Set Colors
    if (isMyMessage)
    {
        self.backgroundColor = blueColor;
        self.ackTitleLabel.textColor = whiteColor;
    }
    else
    {
        if (isMessageHaveAttachment)
        {
            self.backgroundColor = blueColor;
            self.ackTitleLabel.textColor = whiteColor;
        }
        else
        {
            self.backgroundColor = whiteColor;
            self.ackTitleLabel.textColor = blueColor;
        }
    }
    
    switch (state)
    {
        case AckViewStateAckNeeded: {
            
            labelText = QliqLocalizedString(@"1940-StatusNotAcknowledged");
            
            if (self.totalRecipientCount > 1 && self.ackedRecipientCount > 0) {
                labelText  = QliqFormatLocalizedString2(@"1941-StatusAcknowledgedBy", (long)self.ackedRecipientCount, (long)self.totalRecipientCount);
            }
            
            break;
        }
        case AckViewStateAckGot: {
            
            if (self.totalRecipientCount == self.ackedRecipientCount) {
                labelText       = QliqLocalizedString(@"1942-StatusAcknowledged");
                checkmarkImage  = chekedImage;
            }
            else {
                labelText = QliqFormatLocalizedString2(@"1941-StatusAcknowledgedBy", (long)self.ackedRecipientCount, (long)self.totalRecipientCount);
            }
            
            
            break;
        }
        case AckViewStateTapToAck: {
            
            labelText       = QliqLocalizedString(@"1943-StatusTapToAcknowledge");
            checkmarkImage  = notChekedImage;//isMessageHaveAttachment ? notChekedImage : notChekedBlueImage;
            self.backgroundColor = orangeColor;
            self.ackTitleLabel.textColor = whiteColor;
            
            break;
        }
        case AckViewStateAckGiven: {
            
            labelText       = QliqLocalizedString(@"1942-StatusAcknowledged");
            checkmarkImage  = isMessageHaveAttachment ? chekedImage : chekedImageBlue;
            
            if (self.totalRecipientCount > 1 && self.ackedRecipientCount > 0) {
                labelText = QliqFormatLocalizedString2(@"1941-StatusAcknowledgedBy", (long)self.ackedRecipientCount, (long)self.totalRecipientCount);
            }
            
            //            if (state_ == AckViewStateTapToAck) {
            //                [self performSelector:@selector(replaceAckView) withObject:nil afterDelay:3.0];
            //            }
            
            break;
        }
        default: break;
    }
    
    self.ackTitleLabel.text = labelText;
    self.checkmarkImageView.image = checkmarkImage;
    state_ = state;
    
    [self setNeedsLayout];
}

- (BOOL)configureAckViewWithMessage:(ChatMessage*)message isMyMessage:(BOOL)myMessage
{
    BOOL hideAckView = YES;
    
    self.ackTitleLabel.font = [UIFont systemFontOfSize:14.f];
    self.checkmarkImageView.image = nil;
    self.alpha = 1.f;
    
    self.totalRecipientCount = message.totalRecipientCount;
    self.ackedRecipientCount = message.ackedRecipientCount;
    
    if (message.ackRequired)
    {
        hideAckView = [message isAcked];
        
        if ([message isAcked] ) {
            hideAckView = NO;
            if(myMessage)
            {
                [self setAckViewWithState:AckViewStateAckGot
                              isMyMessage:myMessage
                         isHaveAttachment:[message isMessageHaveAttachment]];
            }
            else
            {
                [self setAckViewWithState:AckViewStateAckGiven
                              isMyMessage:myMessage
                         isHaveAttachment:[message isMessageHaveAttachment]];
            }
        }
        else {
            [self setAckViewWithState:myMessage ? AckViewStateAckNeeded : AckViewStateTapToAck
                          isMyMessage:myMessage
                     isHaveAttachment:[message isMessageHaveAttachment] ];
        }
    }
    
    return hideAckView;
}

#pragma mark - Private

- (void)replaceAckView
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(replaceAckViewWithString:)])
        [self.delegate replaceAckViewWithString:self];
}

#pragma mark - GestureReconizersActions

- (void)tapEvent:(UITapGestureRecognizer *)sender
{
    CGPoint touch = [sender locationInView:self];
    if(CGRectContainsPoint(self.bounds, touch) && [self.ackTitleLabel.text isEqual:QliqLocalizedString(@"1943-StatusTapToAcknowledge")])
    {
        [self.delegate ackGotForAckView:self];
        //self.state = AckViewStateAckGiven; //??? Why it is needed ???
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touch = [gestureRecognizer locationInView:self];
    if(CGRectContainsPoint(self.bounds, touch))
        return YES;
    
    return NO;
}

@end
