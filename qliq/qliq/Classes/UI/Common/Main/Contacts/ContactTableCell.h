 //
//  ContactTableCell.h
//  qliq
//
//  Created by Valery Lider on 9/23/14.
//
//

#import <UIKit/UIKit.h>
#import "Conversation.h"

extern NSString * const ContactTableCellId;

@class ContactTableCell;

@protocol ContactsCellDelegate <NSObject>

@optional

- (void)pressRightButton:(QliqGroup *)group;
- (void)pressMessageButton:(id)contact;
- (void)pressPhoneButton:(id)contact;
- (void)pressFavoriteButton:(id)contact;
- (void)pressDeleteButton:(id)contact;

- (void)removeContactButtonPressed:(id)contact;
- (NSString *)getRoleForCareChannelWithUser:(QliqUser *)participant;
- (BOOL)isCareChannel;

- (void)changeParticipant:(id)participant withRole:(NSString *)role fromCell:(ContactTableCell *)cell;
- (void)indexOfActiveCell:(ContactTableCell *)cell;

@end

@interface ContactTableCell : UITableViewCell

@property (weak) id <ContactsCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *rightArrow;

@property (weak, nonatomic) IBOutlet UIView *contactInfoView;
@property (weak, nonatomic) IBOutlet UIView *optionsView;

- (void)setCell:(id)item;
- (void)configureBackroundColor:(UIColor *)color;
- (void)setRightArrowHidden:(BOOL)hidden;
- (void)setRemoveButtonHidden:(BOOL)hidden;

@end
