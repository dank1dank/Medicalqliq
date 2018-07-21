//
//  AddToListViewController.h
//  qliq
//
//  Created by Vita on 7/18/12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomListTableViewCell.h"

@class ContactList;
@protocol AddToListViewControllerDelegate;

@interface AddToListViewController : UIViewController <CustomListCellDelegate>

@property (nonatomic, assign) id <AddToListViewControllerDelegate> delegate;

@property (nonatomic, assign) NSInteger contactId;
@property (nonatomic, assign) BOOL writeUsersToDB;

@end


@protocol AddToListViewControllerDelegate <NSObject>

- (void) addToListViewController:(AddToListViewController *) controller didCheckedList:(ContactList *) list;
- (void) addToListViewController:(AddToListViewController *) controller didUncheckedList:(ContactList *) list;

@end