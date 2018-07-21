//
//  Role.h
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;

@interface Role : NSObject

@property (nonatomic, retain) NSString *name;

+(Role*) roleWithResultSet:(FMResultSet*)rs;


@end
