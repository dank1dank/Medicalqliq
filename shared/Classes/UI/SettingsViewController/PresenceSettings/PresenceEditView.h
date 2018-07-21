//
//  PresenceEditView.h
//  qliq
//
//  Created by Aleksey Garbarev on 16.11.12.
//
//

#import <UIKit/UIKit.h>

#import "Presence.h"

@class PresenceEditView;

@protocol PresenceEditViewDelegate <NSObject>

@optional
- (void)addRecipientWithView:(id)view;

- (void)presenceEditView:(PresenceEditView *)editView didPressedDoneButton:(QliqButton *)button;
- (void)presenceEditView:(PresenceEditView *)editView didPressedCancelButton:(QliqButton *)button;

- (void)presenceEditViewDidBeginEdit:(PresenceEditView *)editView;
- (void)presenceEditViewDidEndEdit:(PresenceEditView *)editView;

@end

@interface PresenceEditView : UIView

@property (nonatomic, unsafe_unretained) id <PresenceEditViewDelegate> delegate;
@property (nonatomic, unsafe_unretained) QliqNavigationController *navigationController;
@property (nonatomic, strong) QliqTextfield *forwardingUserTextField;

- (id)initWithFrame:(CGRect)frame andPresenceType:(NSString *)type;

- (void)setType:(NSString *)type;
- (void)setPresence:(Presence *)presence;
- (void)selectedRecipient:(QliqUser *)contact;

@end
