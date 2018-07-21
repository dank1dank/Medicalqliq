//
//  SuperbillService.h
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DBServiceBase.h"
#import "Superbill.h"

@interface SuperbillDbService : DBServiceBase

-(BOOL) saveSuperbill:(Superbill*)referringProvider;
-(Superbill*) getSuperbill:(NSString*)taxonomyCode;

@end
