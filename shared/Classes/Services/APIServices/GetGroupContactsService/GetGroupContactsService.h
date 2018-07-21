//
//  GetGroupContactsService.h
//  qliq
//
//  Created by Adam Sowa on 3/5/13.
//

#import <Foundation/Foundation.h>

@interface GetGroupContactsService : NSOperation
{
}
+ (GetGroupContactsService *) sharedService;

-(void) getGroupContactsForQliqId:(NSString *)qliqId withCompletition:(CompletionBlock) completetion;

@end
