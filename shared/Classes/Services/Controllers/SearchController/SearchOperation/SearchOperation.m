//
//  SearchOperation.m
//  qliq
//
//  Created by Aleksey Garbarev on 22.11.12.
//
//

#import "SearchOperation.h"

@interface SearchOperation()

@property (nonatomic, strong) NSPredicate * searchPredicate;
@property (nonatomic, strong) NSArray * objectsToSearch;
@property (nonatomic, readwrite, getter = isPredicateCorrect) BOOL predicateCorrect;

@end

@implementation SearchOperation
@synthesize predicateCorrect;
@synthesize searchPredicate, objectsToSearch;
@synthesize batchSize;//, searchBatchesConcurrently;

- (id)initWithArray:(NSArray *)objects andSearchPredicate:(NSPredicate *) _searchPredicate
{
    self = [super init];
    if (self)
    {
        self.searchPredicate    = _searchPredicate;
        self.batchSize          = 0; //20
        self.objectsToSearch    = objects;
//        self.searchBatchesConcurrently = YES;
    }
    
    if(!_searchPredicate)
        return nil;
    
    return self;
}

- (NSPredicate *)predicateForSearchString:(NSString *)searchString withPrioritizedAlphabetically:(BOOL)prioritizedAlphabetically
{
    NSMutableCharacterSet * set = [NSMutableCharacterSet punctuationCharacterSet];
    [set addCharactersInString:@" "];
    
    NSArray * wordsArray = [searchString componentsSeparatedByCharactersInSet:set];
    NSMutableString * predicateFormatString = nil;
    self.predicateCorrect = NO;
    int counter = 0;
    
    if (searchString.length == 3 && wordsArray.count == 2) {
        predicateFormatString = [NSMutableString string];
        self.predicateCorrect = YES;
        [predicateFormatString appendFormat:@"((searchDescription BEGINSWITH[c] '%@') AND (searchDescription CONTAINS[c] ' %@'))", wordsArray[0], wordsArray[1]];
        [predicateFormatString appendFormat:@" OR "];
        [predicateFormatString appendFormat:@"((searchDescription BEGINSWITH[c] '%@') AND (searchDescription CONTAINS[c] ' %@'))", wordsArray[1], wordsArray[0]];

    } else {
        for (NSString * word in wordsArray)
        {
            if (word.length == 0)
                continue;
            
            if (counter == 0)
            {
                predicateFormatString = [NSMutableString string];
                self.predicateCorrect = YES;
            }
            else
                [predicateFormatString appendFormat:@" AND "];
            
            if (prioritizedAlphabetically) {
                [predicateFormatString appendFormat:@"searchDescription BEGINSWITH[c] '%@'", word];
            }
            else {
            [predicateFormatString appendFormat:@"((searchDescription BEGINSWITH[c] '%@') OR (searchDescription CONTAINS[c] ' %@'))", word, word];
            }
            counter++;
        }
    }
    
    return predicateFormatString ? [NSPredicate predicateWithFormat:predicateFormatString] : nil;
}

- (id) initWithArray:(NSArray *)objects andSearchString:(NSString *) searchString withPrioritizedAlphabetically:(BOOL)prioritizedAlphabetically {
    
    NSPredicate * predicate = nil;
    @try {
        predicate = [self predicateForSearchString:searchString withPrioritizedAlphabetically:prioritizedAlphabetically];
    }
    @catch (NSException * exception) {
        DDLogError(@"Exception during creating predicate: %@ %@",[exception name],[exception reason]);
    }
    
    return [self initWithArray:objects andSearchPredicate:predicate];
}

- (void)main {
    
    [self searchWithFoundBlock:^(NSArray *results) {
        if ([self.delegate respondsToSelector:@selector(searchOperation:didFoundResults:)])
            [self.delegate searchOperation:self didFoundResults:results];
    } complete:^{
        if ([self.delegate respondsToSelector:@selector(didCompleteSearchInSearchOperation:)])
            [self.delegate didCompleteSearchInSearchOperation:self];
    }];
}

- (NSArray *) search{
    __block NSMutableArray * allResults = [[NSMutableArray alloc] init];
    [self searchWithFoundBlock:^(NSArray *results) {
        [allResults addObjectsFromArray:results];
    } complete:nil];
    return allResults;
}

- (NSArray *)searchUploadFileForSearchText:(NSString *)searchText {

    __block NSMutableArray * allResults = [[NSMutableArray alloc] init];
    self.searchPredicate = [NSPredicate predicateWithFormat:@"SELF.mediaFile.fileName CONTAINS[c] %@", searchText];

    if (self.batchSize == 0)
    {
        NSArray * results = [self.objectsToSearch filteredArrayUsingPredicate:self.searchPredicate];
        allResults = [results mutableCopy];
    }
    else
    {
        //number of parts to search
        size_t partCount = [self.objectsToSearch count] / self.batchSize + 1;
        for (size_t part = 0; part < partCount; part++)
        {
            if (![self isCancelled])
            {
                NSArray * searchResults = [self searchInBatch:part];
                allResults = [searchResults mutableCopy];
            }
        }
    }
    return allResults;
}

- (void) searchWithFoundBlock:(void(^)(NSArray * results))foundResult complete:(void(^)(void))complete
{

    //if batch size is zero, then search one time in whole contacts array
    if (self.batchSize == 0)
    {
        NSArray * results = [self.objectsToSearch filteredArrayUsingPredicate:self.searchPredicate];
        if(foundResult)
            foundResult(results);
    }
    else
    {
        //number of parts to search
        size_t partCount = [self.objectsToSearch count] / self.batchSize + 1;
        
//        if (self.searchBatchesConcurrently){
//            //search concurrently in global thread in parts of array
//            dispatch_apply(partCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t part) {
//                if (![self isCancelled]){
//                    NSArray * searchResults = [self searchInBatch:part];
//                    if(foundResult && searchResults) foundResult(searchResults);
//                }
//            });
//        }else{
            for (size_t part = 0; part < partCount; part++)
            {
                if (![self isCancelled])
                {
                    NSArray * searchResults = [self searchInBatch:part];
                    if(foundResult && searchResults)
                        foundResult(searchResults);
                }
            }
//        }
    }
    
    if (complete)
        complete();
}

- (NSArray *)searchInBatch:(NSUInteger)part
{
    //calc range of subarray
    NSRange range = { .location = (part * self.batchSize), .length = self.batchSize};
    
    //check that range in bounds
    range.length = MIN(self.objectsToSearch.count - range.location, range.length);
    if (range.location < self.objectsToSearch.count)
    {
        NSArray * searchArray = [self.objectsToSearch subarrayWithRange:range];
        return [searchArray filteredArrayUsingPredicate:self.searchPredicate];
    }
    
    return @[];
}


@end
