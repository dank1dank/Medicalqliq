//
//  SearchRecipientsViewController.m
//  qliqConnect
//
//  Created by Paul Bar on 12/13/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "SearchRecipientsController.h"
#import "ContactGroup.h"
#import "QliqMembersContactGroup.h"
#import "QliqUser.h"
#import "ContactsProvider.h"
#import "QliqContactsProvider.h"
#import "RecepientCell.h"

#import "QliqModelServiceFactory.h"
#import "ContactsProvider.h"
#import "QliqListService.h"
#import "QliqContactsGroup.h"
#import "QliqUserDBService.h"

#import "ContactDBService.h"

typedef NSArray*(^ContactsLoadingBlock)();

@interface SearchRecipientsController() <SearchOperationDelegate>
{
    NSMutableArray * searchResults;
    
    NSOperationQueue * searchOperationsQueue;
    dispatch_queue_t searchResultsModificationQueue;
    dispatch_group_t contactsLoadingGroup;
}

@property (nonatomic, strong) NSArray *contactsToSearch;

@end

@implementation SearchRecipientsController

@synthesize delegate;
@synthesize contactsToSearch = _contactsToSearch;

#pragma mark - Instance methods

- (id)init {
    
    self = [super init];
    if(self) {
        
        searchOperationsQueue = [[NSOperationQueue alloc] init];
        [searchOperationsQueue setMaxConcurrentOperationCount:1];
        
        searchResultsModificationQueue = dispatch_queue_create("SearchResultsModificationQueue", NULL);
        
//        __block id <ContactGroup> targetContactsGrop = [[QliqContactsGroup alloc] init];
//        __block QliqContactsProvider * contactProvider = [[QliqContactsProvider alloc] init];
//        
//        [self loadContactsWithBlock:^NSArray *{
//            
//            NSArray * recipients = [targetContactsGrop getContacts];
//            NSArray *groups = [contactProvider getUserGroups];
//            recipients = [recipients arrayByAddingObjectsFromArray:groups];
//            return recipients;
//        }];
    }
    return self;
}

- (void)dealloc {
    _contactsToSearch = nil;
}

- (void)loadContactsWithBlock:(ContactsLoadingBlock)loadingBlock
{
    dispatch_group_t group = dispatch_group_create();
    contactsLoadingGroup = group;
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.contactsToSearch = loadingBlock();
        contactsLoadingGroup = nil;
    });
}

- (void)reloadContacts {
    
    __block id <ContactGroup> targetContactsGrop = [[QliqContactsGroup alloc] init];
    __block QliqContactsProvider * contactProvider = [[QliqContactsProvider alloc] init];
    
    [self loadContactsWithBlock:^NSArray *{
        
        NSArray * recipients =  [targetContactsGrop getOnlyContacts];//[targetContactsGrop getContacts];
        NSArray *groups = [contactProvider getUserGroups];
        recipients = [recipients arrayByAddingObjectsFromArray:groups];
        return recipients;
    }];
}

- (NSArray *)waitForContactsIfNeeded
{
    if (contactsLoadingGroup != nil)
        dispatch_group_wait(contactsLoadingGroup, 0);

    return self.contactsToSearch;
}

- (id)contactIsQliqUser:(id)enterContact
{
    id item = enterContact;
    
    if ([enterContact isKindOfClass:[Contact class]])
    {
        QliqUser *contact = enterContact;
        if (contact.contactType == ContactTypeQliqUser)
        {
            QliqUserDBService *userDBService = [[QliqUserDBService alloc] init];
            contact = [userDBService getUserWithContactId:contact.contactId];
            item = contact;
        }
    }
    
    return item;
}

- (void)clearSearchResults
{
    //Using searchResultsModificationQueue queue to synchonize array mutation
    dispatch_sync(searchResultsModificationQueue, ^{
        [searchResults removeAllObjects];
        searchResults = nil;
    });
}

- (void)addToSearchResult:(NSArray *)array
{
    dispatch_sync(searchResultsModificationQueue, ^{ ////early be dispatch_sync

        if (!searchResults)
            searchResults = [[NSMutableArray alloc] init];
        
        if (searchResults.count > 0)
        {
            for (id <Recipient> object in array)
            {
                if (![searchResults containsObject:object])
                    [searchResults addObject:object];
            }
        }
        else
        {
            [searchResults addObjectsFromArray:array];
        }
    });
}

- (id<Recipient>)recipientAtIndex:(NSUInteger)index
{
    id <Recipient> recipient = nil;
    if ( index < [searchResults count])
        recipient = [searchResults objectAtIndex:index];
    
    return recipient;
}

#pragma mark - Search methods

- (NSArray *)searchContactsSync:(NSString *)predicate maxCount:(NSInteger)count {
    
    [searchOperationsQueue cancelAllOperations];
    
    __block NSArray * result = nil;
    
    SearchOperation * operation = [[SearchOperation alloc] initWithArray:[self waitForContactsIfNeeded] andSearchString:predicate withPrioritizedAlphabetically:NO];
    
    if (operation)
        result = [operation search];
    
    return result;
}

- (void)searchContactsAsync:(NSString *)predicate
{
    //cancel current searching and clear results
    [searchOperationsQueue cancelAllOperations];
    [self clearSearchResults];
    
    SearchOperation * operation = [[SearchOperation alloc] initWithArray:[self waitForContactsIfNeeded] andSearchString:predicate withPrioritizedAlphabetically:NO];
    if (operation)
    {
        operation.delegate = self;
        [searchOperationsQueue addOperation:operation];
    }
    else
    {
        dispatch_sync_main(^{ //early be dispatch_sync_main
            [self.delegate searchResultsUpdatedForRecipientSearchController:self numberOfResults:0];
        });
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [searchResults count];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *reuseID = @"searchRecipientsViewController";
    RecepientCell * cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    if(cell == nil)
        cell = [[RecepientCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier: reuseID];

    id <Recipient> recepient = [self recipientAtIndex:indexPath.row];
    recepient = [self contactIsQliqUser:recepient];
    [cell setRecepient:recepient];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id <Recipient> selectadRecipient = [self recipientAtIndex:indexPath.row];
    selectadRecipient = [self contactIsQliqUser:selectadRecipient];
    
    if ([selectadRecipient isRecipientEnabled])
    {
        [self.delegate selectedRecipient:selectadRecipient];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else
    {
        UIAlertView_Blocks *alert = [[UIAlertView_Blocks alloc] initWithTitle:nil
                                                                      message:NSLocalizedString(@"1198-TextYouSelectedContactWhoHasNotQliqApp", nil)
                                                                     delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"4-ButtonCancel", nil)
                                                            otherButtonTitles:NSLocalizedString(@"45-ButtonProceed", nil), nil];
        [alert showWithDissmissBlock:^(NSInteger buttonIndex) {
            
            if (buttonIndex != alert.cancelButtonIndex)
            {
                [self.delegate selectedRecipient:selectadRecipient];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField.tag == 101) {
        return NO;
    }
    [self.delegate searchRecipientsViewControllerWillStartSearching:self];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if([self.delegate searchRecipientsViewControllerShouldEndSearching:self])
    {
        [textField resignFirstResponder];
        return YES;
    }
    else 
    {
        return NO;
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if([self.delegate searchRecipientsViewControllerShouldEndSearching:self])
    {
        [textField resignFirstResponder];
        return YES;
    }
    else 
    {
        return NO;
    }
}

- (void)textFieldDidDeleteBackward:(QliqTextfield *)textField {
    [self searchContactsAsync:textField.text];
}

- (void)textFieldDidDeleteBackwardOnEmpty:(QliqTextfield *)textField {
    if ([self.delegate respondsToSelector:@selector(selectedRecipient:)]) {
//        [self.delegate selectedRecipient:nil];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *searchString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [self searchContactsAsync:searchString];

    if (searchString.length <= 0) {
        if ([self.delegate respondsToSelector:@selector(selectedRecipient:)]) {
            [self.delegate setEptyRecipient];
        }
    }
    
    return YES;
}

#pragma mark - UIScroll Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
//    NSLog(@"Will begin dragging");
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
//    NSLog(@"Did Scroll");
}

#pragma mark - SearchOperationDelegate

- (void) searchOperation:(SearchOperation *)operation didFoundResults:(NSArray *)array
{
    [self addToSearchResult:array];
    dispatch_sync_main(^{ //early be dispatch_sync_main
        [self.delegate searchResultsUpdatedForRecipientSearchController:self numberOfResults:[searchResults count]];
    });
}

@end
