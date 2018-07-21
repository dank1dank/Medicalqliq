//
//  ReferringProviderService.h
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DBServiceBase.h"
#import "ReferringProvider.h"

@interface ReferringProviderDbService : DBServiceBase

-(BOOL) saveReferringProvider:(ReferringProvider*)referringProvider;
-(ReferringProvider*) getReferringProviderWithNpi:(NSNumber*)npi;
-(NSArray*) getReferringProviders;

@end
