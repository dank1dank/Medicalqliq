//
//  GetMultiParty.h
//  qliq
//
//  Created by Ravi Ada on 11/22/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QliqAPIService.h"

@interface GetMultiPartyService : QliqAPIService

- (id) initWithQliqId:(NSString *) multiPartyQliqId;
- (void) handleError:(NSError*) error;

+ (BOOL) hasOutstandingRequestForMultipartyQliqId:(NSString *)qliqId;

@end
