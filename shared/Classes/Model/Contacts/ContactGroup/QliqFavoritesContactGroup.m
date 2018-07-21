    //
//  QliqFavoritesContactGroup.m
//  qliqConnect
//
//  Created by Paul Bar on 12/12/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "QliqFavoritesContactGroup.h"
#import "FavoriteContactDBObject.h"
#import "Contact.h"
#import "QliqUserDBService.h"


@interface QliqFavoritesContactGroup()

-(BOOL) alreadyInFavorites:(Contact *) contact;

@end

@implementation QliqFavoritesContactGroup

- (BOOL) containsContact:(Contact *)contact
{
    return [self alreadyInFavorites:contact];
}

-(void) removeContact:(Contact *)contact
{
    if([self alreadyInFavorites:contact])
    {
		FavoriteContactDBObject *obj = [[FavoriteContactDBObject alloc] init];
		obj.contact_id = [NSString stringWithFormat:@"%ld",(long)[contact  contactId]];
		[obj remove];
        [obj release];
	}
}

- (NSArray *)getOnlyContacts {
    return [self getVisibleContacts];
}

- (NSArray *) getVisibleContacts{
    return [self getContacts];
}

- (NSArray *)getContactsWithLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex andIsVisible:(BOOL)onlyVisible {
    
    return [self getContacts];
}

- (BOOL)locked{
    return NO;
}


-(NSArray*) getContacts
{
    NSArray *favoriteDBObjects = [FavoriteContactDBObject getAllFavoriteContactsDbObjects];
    NSMutableArray *mutableRez = [[NSMutableArray alloc] initWithCapacity:[favoriteDBObjects count]];
    
    for(FavoriteContactDBObject *dbObj in favoriteDBObjects)
    {
        int contactType = [[dbObj contact_type] intValue];                
        id contact = nil;
        
        switch (contactType)
        {
            case ContactTypeQliqUser: {
                contact = [[QliqUserDBService sharedService] getUserWithContactId:[dbObj.contact_id intValue]];
                break;
            }
            
            default:
                break;
        }
        if(contact != nil)
        {
            [mutableRez addObject:contact];
        }
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    
    return rez;
}

- (NSUInteger)getPendingCount{

    uint count = 0;
    NSArray * contacts = [self getContacts];
    for (Contact *contact in contacts){
        if (contact.contactStatus == ContactStatusNew) count++;
    }
    return count;
    
}

- (NSArray *)getNewContacts{
    NSMutableArray * newContacts = [[NSMutableArray alloc] init];
    NSArray * contacts = [self getContacts];
    for (Contact * contact in contacts){
        if (contact.contactStatus == ContactStatusNew)
            [newContacts addObject:contact];
    }
    
    if ([newContacts count] == 0) {
        [newContacts release];
        newContacts = nil;
    } else {
        [newContacts autorelease];
    }
    
    return newContacts;
}

-(void) addContact:(Contact *)contact
{
    if(![self alreadyInFavorites:contact])
    {
		FavoriteContactDBObject *obj = [[FavoriteContactDBObject alloc] init];
		obj.contact_type = [NSNumber numberWithInt:[contact contactType]];
		obj.contact_id = [NSString stringWithFormat:@"%ld",(long)contact.contactId];
		[obj save];
        [obj release];
	}
}

-(NSString *) name
{
    return @"Favorites";
}



#pragma mark -
#pragma mark Private

- (BOOL)alreadyInFavorites:(Contact *)contact //TODO this method needs optimization
{
    NSArray *favorites = [self getContacts]; //right here
    for(Contact * favorite in favorites)
    {
        if(favorite.contactId == contact.contactId)
        {
            return YES;
        }
    }
    return NO;
}

@end
