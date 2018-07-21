//
//  SelectParticipantsTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 8/4/14.
//
//

#import <UIKit/UIKit.h>

@class QliqGroup, QliqUser;

@interface SelectParticipantsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UILabel *title;

@property (nonatomic, weak) QliqGroup *group;
@property (nonatomic, weak) QliqUser *user;

- (void)setData:(id)item;
- (void)setCheckedBox:(BOOL)isCheked;

@end
