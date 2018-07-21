//
//  DetailOnCallTableViewCell.h
//  qliq
//
//  Created by Valerii Lider on 07/09/15.

#import <UIKit/UIKit.h>

#import "OnCallGroup.h"

@class QliqUserWithHours;
@class OnCallShift;
@class DetailOnCallTableViewCell;

@protocol DetailOnCallTableViewCellDelegate <NSObject>

- (void)onNotesButtonPressedInCell:(DetailOnCallTableViewCell *)cell;

@end

@interface DetailOnCallTableViewCell : UITableViewCell

@property (weak) id <DetailOnCallTableViewCellDelegate> delegate;

- (void)configureCellWithQliqUserWithHours:(QliqUserWithOnCallHours *)user withTodayDate:(NSDate *)todayDate withSelectedDate:(NSDate *)selectedDate withNotes:(OnCallMemberNotes *)notes isOnCallUsersWithHours:(BOOL)isOnCallUsersWithHours;

@end
