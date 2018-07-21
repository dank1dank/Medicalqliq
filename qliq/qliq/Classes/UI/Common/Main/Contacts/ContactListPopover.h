//
//  ContactListPopover.h
//  qliq
//
//  Created by Valerii Lider on 10/20/14.
//
//

typedef NS_ENUM(NSInteger, ContactLists) {
    ContactListAll = 0,
    ContactListOnlyQliq,
    ContactListAvialable,
    ContactListDoNotDistrub,
    ContactListAway,
    ContactListIphoneContact
};

#import <UIKit/UIKit.h>

@protocol ContactListPopoverDelegate <NSObject>

- (void)pressedSortOption:(ContactLists)option;

@end

@interface ContactListPopover : UIView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) id <ContactListPopoverDelegate> delegate;

@property (nonatomic, assign) ContactLists currentContactList;
@property (nonatomic, assign) CGFloat heightForRow;
@property (nonatomic, strong) NSMutableArray *content;

@end
