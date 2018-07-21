//
//  FriendsBoxView.h
//  CarZ
//
//  Created by Ivan Zezyulya on 30.03.12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Recipient.h"

@protocol FriendsBoxViewDelegate;


@interface FriendsBoxView : UIView

@property (nonatomic, unsafe_unretained) id <FriendsBoxViewDelegate> delegate;
@property (nonatomic, readonly) int ridersNumber;

- (void) addRecipient:(id<Recipient> )recipient;
- (void) removeRecipient:(id<Recipient>)recipient;

@end


@protocol FriendsBoxViewDelegate <NSObject>

- (void) friendsBoxViewDidChangeFrame:(FriendsBoxView *)view;
- (void) friendsBoxViewInputFieldDidChangeTextTo:(NSString *)text;
- (void) friendsBoxViewInputFieldDidBeginEditing;
- (void) friendsBoxViewInputFieldDidEndEditing;
- (void) friendsBoxViewWantsRemoveRecipient:(id <Recipient>)rider;

@end