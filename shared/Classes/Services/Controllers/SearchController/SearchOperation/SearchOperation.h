//
//  SearchOperation.h
//  qliq
//
//  Created by Aleksey Garbarev on 22.11.12.
//
//

#import <Foundation/Foundation.h>

@protocol Searchable <NSObject>

//Returns string where search will performed
- (NSString *) searchDescription;

@end

@class SearchOperation;
@protocol SearchOperationDelegate <NSObject>

@optional
- (void) searchOperation:(SearchOperation *) operation didFoundResults:(NSArray *) array;
- (void) didCompleteSearchInSearchOperation:(SearchOperation *) operation;

@end


@interface SearchOperation : NSOperation

@property (nonatomic, unsafe_unretained) id <SearchOperationDelegate> delegate;

/* Number of items in searching parts, if batchSize = 0 - search in one part. Default: 20 */
@property (nonatomic, readwrite) NSUInteger batchSize;

//@property (nonatomic, readwrite) BOOL searchBatchesConcurrently;

/* objects in 'objects' array should implement Searchable protocol */

/* If can't create predicate from search string - returns nil. Do checking for this - it means that searchString is bad*/
- (id) initWithArray:(NSArray *)objects andSearchString:(NSString *) searchString withPrioritizedAlphabetically:(BOOL)prioritizedAlphabetically;
- (id) initWithArray:(NSArray *)objects andSearchPredicate:(NSPredicate *) searchPredicate;


/* Sync api */
- (NSArray *) search;
- (NSArray *)searchUploadFileForSearchText:(NSString *)searchText;
- (void) searchWithFoundBlock:(void(^)(NSArray * results))foundResult complete:(void(^)(void))complete;

- (BOOL) isPredicateCorrect;

@end
