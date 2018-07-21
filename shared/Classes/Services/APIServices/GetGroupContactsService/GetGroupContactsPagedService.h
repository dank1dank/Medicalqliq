//
//  GetGroupContactsPagedService.h
//  qliq
//
//  Created by Adam Sowa on 17/12/2014.
//

#import <Foundation/Foundation.h>

@interface GetGroupContactsPagedService : NSOperation

- (void) getGroupContactsForQliqId:(NSString *)qliqId withCompletition:(CompletionBlock)completetion;

@end
