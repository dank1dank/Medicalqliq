//
//  SearchContactsService.h
//  qliq
//
//  Created by Adam Sowa on 26.11.2015
//
//

#import <Foundation/Foundation.h>

@interface SearchContactsService : NSOperation

+ (SearchContactsService *)sharedService;

+ (BOOL)searchContactsIfNeeded:(NSString *)filter count:(NSInteger)count completion:(CompletionBlock)completion;

- (void)searchContacts:(NSString *)filter count:(NSInteger)count completion:(CompletionBlock)completion;


@end
