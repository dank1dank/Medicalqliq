//
//  ModifyMultiParty.h
//  qliq
//
//  Created by Ravi Ada on 11/22/12.
//  Copyright (c) 2012 qliqSoft Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "QliqAPIService.h"
#import "Recipients.h"

@interface ModifyMultiPartyService : QliqAPIService

- (id)initWithRecipients:(Recipients *)recipients modifiedRecipients:(Recipients *)newRecipients;

@end
