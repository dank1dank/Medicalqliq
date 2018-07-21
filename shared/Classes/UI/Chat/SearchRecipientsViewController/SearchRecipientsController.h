//
//  SearchRecipientsViewController.h
//  qliqConnect
//
//  Created by Paul Bar on 12/13/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchContactsController.h"
#import "Recipient.h"

@class SearchRecipientsController;

@protocol SearchRecipientsViewControllerDelegate <NSObject>

- (void)setEptyRecipient;
- (void)selectedRecipient:(id<Recipient>)contact;
- (void)searchResultsUpdatedForRecipientSearchController:(SearchRecipientsController *)controller numberOfResults:(NSInteger)numOfResults;
- (void)searchRecipientsViewControllerWillStartSearching:(SearchRecipientsController *)controller;
- (BOOL)searchRecipientsViewControllerShouldEndSearching:(SearchRecipientsController *)controller;

@end

@interface SearchRecipientsController : NSObject <QliqTextfieldDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readonly, strong) NSArray * contactsToSearch;

@property (nonatomic, assign) id<SearchRecipientsViewControllerDelegate> delegate;

- (NSArray *) searchContactsSync:(NSString *)predicate maxCount:(NSInteger) count;
- (void) searchContactsAsync:(NSString *)predicate;

- (void)reloadContacts;

@end
