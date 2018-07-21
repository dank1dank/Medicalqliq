//
//  ContactsProvider.h
//  qliqConnect
//
//  Created by Paul Bar on 11/30/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ContactsProvider <NSObject>

-(NSArray*) getContactGroups;
-(NSArray*) searchContacts:(NSString*)predicate;
-(NSArray*) getContactRequests;
-(void) searchContactsAsync:(NSString*)predicate;

@end
