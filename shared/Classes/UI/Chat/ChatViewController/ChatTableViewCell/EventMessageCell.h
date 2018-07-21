//
//  EventMessageCell.h
//  qliq
//
//  Created by Aleksey Garbarev on 27.12.12.
//
//

#import <UIKit/UIKit.h>

#import "ChatMessage.h"

@protocol MessageCellProtocol;

@interface EventMessageCell : UITableViewCell

@property (nonatomic, strong) ChatMessage * message;

+ (CGFloat) heightForRowWithMessage:(ChatMessage *) _message;

@end
