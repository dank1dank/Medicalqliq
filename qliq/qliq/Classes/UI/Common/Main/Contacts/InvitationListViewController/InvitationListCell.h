//
//  InvitationListCell.h
//  qliq
//
//  Created by Valerii Lider on 3/17/15.
//
//



#import <UIKit/UIKit.h>

@class Invitation;
@class InvitationListCell;

@protocol InvitationListCellDelegate <NSObject>

- (void)invitationListCell:(InvitationListCell *)cell viewDidTappedWithInvitation:(Invitation *)invitation;

@end


@interface InvitationListCell : UITableViewCell

@property (nonatomic, weak) id <InvitationListCellDelegate> delegate;

- (void)setCellInvitation:(Invitation *)invitation;

@end
