//
//  SearchRecipientsViewController.h
//  qliqConnect
//
//  Created by Paul Bar on 12/13/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QliqModelServiceFactory.h"
#import "ContactsProvider.h"
#import "SearchContactsController.h"
#import "Contact.h"
@class SearchContactsController;
@class SearchRecipientsViewController;
@protocol ContactsProvider;
@protocol Contact;

@protocol SearchRecipientsViewControllerDelegate <NSObject>

-(void) selectedRecipient:(Contact *) contact;
-(void) searchResultsUpdatedForRecipientSearchController:(SearchRecipientsViewController*)controller numberOfResults:(NSInteger)numOfResults;
-(void) searchRecipientsViewControllerWillStartSearching:(SearchRecipientsViewController*)controller;
-(BOOL) searchRecipientsViewControllerShouldEndSearching:(SearchRecipientsViewController*)controller;

@end

@interface SearchRecipientsViewController : NSObject <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, SearchContactsDelegate>
{
    NSMutableArray *dataArray;    
}

@property (nonatomic, assign) id<SearchRecipientsViewControllerDelegate> delegate;

@property (nonatomic, readonly, retain) SearchContactsController *searchContactsController;

@end
