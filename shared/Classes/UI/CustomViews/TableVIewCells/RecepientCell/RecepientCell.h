//
//  RecepientCell.h
//  qliq
//
//  Created by Aleksey Garbarev on 11/23/12.
//
//

#import <UIKit/UIKit.h>

#import "Recipient.h"

@interface RecepientCell : UITableViewCell

@property (nonatomic, unsafe_unretained) id <Recipient> recepient;

- (void) setRecepient:(id<Recipient>)recepient;


@end
