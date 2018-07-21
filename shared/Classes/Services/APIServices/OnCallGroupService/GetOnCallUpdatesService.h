//
//  GetOnCallGroupUpdates.h
//  qliq
//
//  Created by Adam Sowa on 10/01/17.
//
//

#import <Foundation/Foundation.h>

@interface GetOnCallUpdatesService : NSObject

- (void) getWithCompletionBlock:(CompletionBlock) completion;

@end
