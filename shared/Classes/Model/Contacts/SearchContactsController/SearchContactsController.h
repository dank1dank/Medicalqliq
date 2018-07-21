//
//  SearchContactsController.h
//  qliq
//
//  Created by Paul Bar on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SearchOperation.h"

@protocol SearchContactsDelegate <NSObject>

-(void) foundSearchResultsPart:(NSArray*)results;

@end

@interface SearchContactsController : NSObject
{
    NSOperationQueue *searchOperationsQueue;
}

@property (nonatomic, assign) id<SearchContactsDelegate> delegate;
@property (nonatomic, retain) NSArray *contacts;

-(void) searchContactsAsync:(NSString *)predicate;
- (NSArray *) searchContactsSync:(NSString *)predicate maxCount:(NSInteger) count;

@end
