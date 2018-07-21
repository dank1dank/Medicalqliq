//
//  SearchContactsController.m
//  qliq
//
//  Created by Paul Bar on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchContactsController.h"
#import "Contact.h"
#import "NSString+extensions.h"

@interface SearchContactsController ()<SearchOperationDelegate>

@end

@implementation SearchContactsController
@synthesize delegate;
@synthesize contacts;

- (id) init {
    self = [super init];
    if(self)
    {
        searchOperationsQueue = [[NSOperationQueue alloc] init];
        [searchOperationsQueue setMaxConcurrentOperationCount:1];
    }
    return self;
}


- (NSArray *) searchContactsSync:(NSString *)predicate maxCount:(NSInteger) count{
    
    [searchOperationsQueue cancelAllOperations];
    
    __block NSArray * result = nil;
    
    SearchOperation * operation = [[SearchOperation alloc] initWithArray:self.contacts andSearchString:predicate withPrioritizedAlphabetically:NO];
   
    if (operation){
        result = [operation search];
    }
    
    return result;
}

- (void) searchContactsAsync:(NSString *)predicate{
    [searchOperationsQueue cancelAllOperations];

    SearchOperation * operation = [[SearchOperation alloc] initWithArray:self.contacts andSearchString:predicate withPrioritizedAlphabetically:NO];
    if (operation){
        operation.delegate = self;
        [searchOperationsQueue addOperation:operation];
    }else{
        [self.delegate foundSearchResultsPart:[NSArray array]];
    }
}

#pragma mark -
#pragma mark searchOperationDelegate

- (void) searchOperation:(SearchOperation *)operation didFoundResults:(NSArray *)array{
    [self.delegate foundSearchResultsPart:array];
}


@end
