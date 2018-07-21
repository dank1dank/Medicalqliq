//
//  SearchPatientsService.h
//  qliq
//
//  Created by Adam Sowa on 13/01/17.
//
//

#import <Foundation/Foundation.h>
#import "FhirResources.h"

@interface SearchPatientsServiceQuery : NSObject

@property (nonatomic, strong) NSString *qliqStorQliqId;
@property (nonatomic, strong) NSString *searchUuid;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *dob; // must be: yyyy-MM-dd
@property (nonatomic, strong) NSString *mrn;
@property (nonatomic, strong) NSString *lastVisit;
@property (nonatomic, assign) BOOL      myPatientsOnly;

@end

@interface SearchPatientsServiceResult : NSObject

@property (nonatomic, strong) NSString *searchUuid;
@property (nonatomic, assign) NSInteger totalCount;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, assign) NSInteger perPage;
@property (nonatomic, assign) NSInteger totalPages;
@property (nonatomic, strong) FhirPatientArray *patients;
@property (nonatomic, strong) NSString *emrSourceQliqId;
@property (nonatomic, strong) NSString *emrSourceDeviceUuid;
@property (nonatomic, strong) NSString *emrSourcePublicKey;

@end

typedef BOOL (^IsCancelledBlock)();

@interface SearchPatientsService : NSObject

/// isCancelledBlock is optional (can be nil) and should return true if response processing should be cancelled (ie. UI view is already gone)
- (void) call:(SearchPatientsServiceQuery *)query page:(int)page perPage:(int)perPage
               withCompletition:(CompletionBlock)completitionBlock withIsCancelled:(IsCancelledBlock)isCancelledBlock;

@end
