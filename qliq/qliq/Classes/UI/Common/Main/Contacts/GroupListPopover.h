//
//  GroupListPopover.h
//  qliq
//
//  Created by Valerii Lider on 1/13/15.
//
//

typedef NS_ENUM(NSInteger, GroupList) {
    GroupListQrgGroups = 0,
    GroupListMyGroups,
    GroupListOnCallGroups
};

#import <UIKit/UIKit.h>

@protocol GroupListPopoverDelegate <NSObject>

- (void)pressedGroupSortOption:(GroupList)option;

@end

@interface GroupListPopover : UIView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) id <GroupListPopoverDelegate> delegate;


@property (nonatomic, assign) GroupList currentGroup;
@property (nonatomic, assign) CGFloat heightForRow;
@property (nonatomic, strong) NSMutableArray *content;


@end
