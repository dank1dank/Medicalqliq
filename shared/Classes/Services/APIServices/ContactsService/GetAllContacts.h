//
//  GetAllContacts.h
//  qliq
//
//  Created by Ravi Ada on 05/29/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol GetAllContactsDelegate <NSObject>

-(void) getAllContactsSuccess;
-(void) didFailToGetAllContactsWithReason:(NSString*)reason;

@end

@interface GetAllContacts : NSOperation
{
}
+ (GetAllContacts *) sharedService;

-(void) getAllContactsWithCompletition:(CompletionBlock) completetion;
-(void) getAllContacts;

@property (nonatomic, assign) id<GetAllContactsDelegate> delegate UNAVAILABLE_ATTRIBUTE;//Use blocks interface instead

@end
