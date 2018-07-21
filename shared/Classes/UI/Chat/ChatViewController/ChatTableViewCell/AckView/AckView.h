//
//  AckView.h
//  qliqConnect
//
//  Created by Paul Bar on 11/29/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AckView;

typedef NS_ENUM(NSInteger, AckViewState) {
    AckViewStateAckNeeded = 0,
    AckViewStateAckGot,
    AckViewStateTapToAck,
    AckViewStateAckGiven
};

@protocol AckViewDelegate <NSObject>

- (void)ackGotForAckView:(AckView*)ackView;
- (void)replaceAckViewWithString:(AckView*)ackView;

@end

@interface AckView : UIView
{
    AckViewState state_;
}

/** Delegate */
@property (nonatomic, assign) id<AckViewDelegate> delegate;

/** IBOUtlets */
@property (nonatomic, strong) IBOutlet UIImageView *checkmarkImageView;
@property (nonatomic, strong) IBOutlet UILabel *ackTitleLabel;

/** Data */
@property (nonatomic, assign) AckViewState state;
@property (nonatomic, assign) NSInteger totalRecipientCount;
@property (nonatomic, assign) NSInteger ackedRecipientCount;

- (void)setAckViewWithState:(AckViewState)state isMyMessage:(BOOL)isMyMessage isHaveAttachment:(BOOL)isMessageHaveAttachment;
- (BOOL)configureAckViewWithMessage:(ChatMessage*)message isMyMessage:(BOOL)myMessage;

@end
