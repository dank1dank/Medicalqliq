//
//  MockContactsProvider.m
//  qliqConnect
//
//  Created by Paul Bar on 11/30/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "MockContactsProvider.h"
#import "MockContactGroup.h"
#import "Contact.h"
#import "QliqAddressBookContactGroup.h"

@implementation MockContactsProvider
-(id) init
{
    self = [super init];
    if(self)
    {
        
    }
    return self;
}

-(void) dealloc
{
    [super dealloc];
}

-(NSArray*) getContactGroups
{
    NSArray *names = [NSArray arrayWithObjects: @"All contacts",
                      @"My Qliq",
                      @"Memorial hospital",
                      @"Morissvilille Family Medicine",
                      @"Referals",
                      nil];
    NSMutableArray *mutableResult = [[NSMutableArray alloc] initWithCapacity:[names count]];
    
    for(NSString *name in names)
    {
        MockContactGroup *cg = [[MockContactGroup alloc] init];
        cg.name = name;
        [mutableResult addObject:cg];
        [cg release];
    }
    
    QliqAddressBookContactGroup *cg = [[QliqAddressBookContactGroup alloc] init];
    [mutableResult addObject:cg];
    [cg release];
    
    NSArray *rez = [NSArray arrayWithArray:mutableResult];
    [mutableResult release];
    return rez;
}

-(NSArray*) searchContacts:(NSString *)predicate
{
    NSArray *names = [NSArray arrayWithObjects:
                      @"Bulbasaur",
                      @"Ivysaur",
                      @"Venusaur",
                      @"Charmander",
                      @"Charmeleon",
                      @"Charizard",
                      @"Squirtle",
                      @"Wartortle",
                      @"Blastoise",
                      @"Caterpie",
                      @"Metapod",
                      @"Butterfree",
                      @"Weedle",
                      @"Kakuna",
                      @"Beedrill",
                      @"Pidgey",
                      @"Pidgeotto",
                      @"Pidgeot",
                      @"Rattata",
                      @"Raticate",
                      @"Spearow",
                      @"Fearow",
                      @"Ekans",
                      @"Arbok",
                      @"Pikachu",
                      nil];
    NSMutableArray *mutableRez = [[NSMutableArray alloc] initWithCapacity:[names count]];
    
    for(NSString* name in names)
    {
        Contact *contact = [[Contact alloc] init];
        contact.firstName = name;
        contact.lastName = @"Pokemon";
        [mutableRez addObject:contact];
        [contact release];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    return  rez;
}

-(NSArray*)getContactRequests
{
    NSMutableArray *contactRequests = [[NSMutableArray alloc] init];
    
    Contact *contact = [[[Contact alloc] init] autorelease];
    contact.firstName = @"Request";
    contact.lastName = @"Test";
    
    [contactRequests addObject:contact];
    
    NSArray *rez = [NSArray arrayWithArray:contactRequests];
    [contactRequests release];
    return rez;
}

-(void) searchContactsAsync:(NSString *)predicate
{
    
}

@end
