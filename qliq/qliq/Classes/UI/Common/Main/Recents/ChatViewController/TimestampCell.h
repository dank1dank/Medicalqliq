//
//  TimestampCell.h
//  qliq
//
//  Created by Valeriy Lider on 10/1/14.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MessageHistroryMode) {
    MessageHistroryModeAllHistory,
    MessageHistroryModeHostryForQliqId
};

@class MessageStatusLog, ChatMessage;

@interface TimestampCell : UITableViewCell

- (void)setCellWithMessage:(ChatMessage*)message withMessageStatusLog:(MessageStatusLog*)messageLog isGroupMessage:(BOOL)isGroupMessage whithSelectedQliqUser:(QliqUser*)user;

@end
