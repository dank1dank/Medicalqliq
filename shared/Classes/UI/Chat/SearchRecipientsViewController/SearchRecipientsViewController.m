//
//  SearchRecipientsViewController.m
//  qliqConnect
//
//  Created by Paul Bar on 12/13/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "SearchRecipientsViewController.h"
#import "Contact.h"
#import "ContactTableViewCell.h"
#import "ContactGroup.h"
#import "QliqMembersContactGroup.h"
#import "ContactAvatarService.h"
#import "QliqUser.h"
#import "ContactsProvider.h"
#import "QliqContactsProvider.h"

@interface SearchRecipientsViewController() 

-(void) searchContacts:(NSString*)predicate;
-(NSArray*) filterContacts:(NSArray*)contacts;
@property (nonatomic, retain) SearchContactsController *searchContactsController;
@property (nonatomic, retain) ContactAvatarService *contactAvatarService;

@end

@implementation SearchRecipientsViewController{
    NSArray * contactsToSearch;
}

@synthesize delegate = delegate;
@synthesize searchContactsController;
@synthesize contactAvatarService;

-(id) init
{
    self = [super init];
    if(self)
    {
        searchContactsController = [[SearchContactsController alloc] init];
        searchContactsController.delegate = self;
        
        dataArray = [[NSMutableArray alloc] init];
        
        id <ContactGroup> targetContactsGrop = [[QliqMembersContactGroup alloc] init];
        
        QliqContactsProvider * contactProvider = [[QliqContactsProvider alloc] init];
        NSArray * userGroups = [contactProvider getUserGroups];
        
        
        contactsToSearch = [targetContactsGrop getContacts];
        
        contactAvatarService = [[ContactAvatarService alloc] init];
    }
    return self;
}


#pragma mark -
#pragma mark UITableViewDataSource

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [dataArray count];
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseID = @"searchRecipientsViewController";
    ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    if(cell == nil)
    {
        cell = [[ContactTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier: reuseID];
    }
    
    Contact *contact = [dataArray objectAtIndex:indexPath.row];
    [cell setContact:contact];    
    
    return cell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

#pragma mark -
#pragma mark UITableViewDelegate

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    QliqUser *selectadRecipient = [dataArray objectAtIndex:indexPath.row];
    if ([selectadRecipient isActive]){
        [self.delegate selectedRecipient:selectadRecipient];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}


#pragma mark -
#pragma mark UITextFieldDelegate

-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    [self.delegate searchRecipientsViewControllerWillStartSearching:self];
    return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
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

-(BOOL) textFieldShouldEndEditing:(UITextField *)textField
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

- (void) textFieldDidDeleteBackward:(QliqTextfield *) textField{
    [dataArray removeAllObjects];
    [self.searchContactsController setContacts:contactsToSearch];
    [self.searchContactsController searchContactsAsync:textField.text];
}

-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{

    NSString *searchString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    [dataArray removeAllObjects];
    [self.searchContactsController setContacts:contactsToSearch];
    [self.searchContactsController searchContactsAsync:searchString];

    return YES;
}

#pragma mark -
#pragma mark Private

-(void) searchContacts:(NSString *)predicate
{
}

-(NSArray*) filterContacts:(NSArray *)contacts
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    for(Contact *contact in contacts)
    {
        if([contact isKindOfClass:[QliqUser class]])
        {
            if ([(QliqUser*)contact isActive]) {
                [mutableRez addObject:contact];
            }
        }
    }
    
    return mutableRez;
}


#pragma mark -
#pragma mark searchContactsDelegate

- (BOOL) searchContainContact:(Contact *) contact{
    return [dataArray containsObject:contact];
}


    
    
-(void) addResultsToTableView:(NSArray*)results
{
    for (Contact * object in results) {
        if (![self searchContainContact:object]){
            [dataArray addObject:object];
        }
    }
//    [dataArray addObjectsFromArray:results];
    [self.delegate searchResultsUpdatedForRecipientSearchController:self numberOfResults:[dataArray count]];
}

-(void)foundSearchResultsPart:(NSArray *)results
{
//    NSArray *filtredContacts = [self filterContacts:results];
    [self performSelectorOnMainThread:@selector(addResultsToTableView:) withObject:results waitUntilDone:NO];
    
}
@end
