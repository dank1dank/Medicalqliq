//
//  QliqChargeModule.h
//  qliq
//
//  Created by Paul Bar on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QliqModuleBase.h"
#import "DataServerClient.h"

@interface QliqChargeModule : QliqModuleBase<QliqStoreQueryDelegate>
{
}

// protocol QliqModule
-(BOOL) processSipMessage:(QliqSipMessage*)message;
-(void) onSipRegistrationStatusChanged:(BOOL)registered;
-(UIImage*) moduleLogo;

// protocol DataServerCallback
- (BOOL) onQueryPageReceived: (NSString *)qliqId: (NSString *)subject: (NSString *)requestId: (NSArray *)results: (int)page: (int)pageCount: (int)totalPages;
- (BOOL) onQueryResultReceived: (NSString *)qliqId: (NSString *)subject: (NSString *)requestId: (NSDictionary *)result;
- (void) onQuerySent: (NSString *)qliqId: (NSString *)subject: (NSString *)requestId;
- (void) onQuerySendingFailed: (NSString *)qliqId: (NSString *)subject: (NSString *)requestId;
- (void) onQueryFinished: (NSString *)qliqId: (NSString *)subject: (NSString *)requestId withStatus:(int)status;

@end
