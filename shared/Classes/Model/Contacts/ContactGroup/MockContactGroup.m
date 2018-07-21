//
//  MockContactGroup.m
//  qliqConnect
//
//  Created by Paul Bar on 11/30/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "MockContactGroup.h"
#import "Contact.h"

@implementation MockContactGroup
@synthesize name;

- (NSArray *)getContactsWithLimitFrom:(NSUInteger)startIndex to:(NSUInteger)countIndex andIsVisible:(BOOL)onlyVisible
{
    NSArray *array = @[];
    
    return array;
}

-(id) init
{
    self = [super init];
    if(self)
    {
        
    }
    return self;
}

- (NSArray *)getNewContacts{
    return nil;
}

- (BOOL)locked{
    return NO;
}


-(void) dealloc
{
    [super dealloc];
}

- (NSUInteger)getPendingCount{
    
    uint count = 0;
    NSArray * contacts = [self getContacts];
    for (Contact *contact in contacts){
        if (contact.contactStatus == ContactStatusNew) count++;
    }
    return count;

}

- (NSArray *)getOnlyContacts {
    return [self getVisibleContacts];
}

- (NSArray *) getVisibleContacts{
    return [self getContacts];
}

-(NSArray*) getContacts
{
    NSArray *alphabet = [[[NSArray alloc]initWithObjects:@"",@"",@"A",@"asd",@"asd",@"abc",@"aaa",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",
                @"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"",@"",nil] autorelease];
    
    NSMutableArray *mutableRez = [[[NSMutableArray alloc] initWithCapacity: [alphabet count]] autorelease];
    for(NSInteger i = [alphabet count] -1; i>=0; i--)
    {
        NSString *_name = [alphabet objectAtIndex:i];
        Contact *contact = [[Contact alloc] init];
        contact.firstName = _name;
        contact.lastName = _name;
        [mutableRez addObject:contact];
        [contact release];
    }
    return mutableRez;
}

-(void) addContact:(Contact *)contact
{
    
}

@end
