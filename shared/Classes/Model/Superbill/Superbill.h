//
//  Superbill.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/18/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FMResultSet;

@interface Superbill : NSObject {
	NSString *taxonomyCode;
    NSString *name;
	NSString *data;
	NSArray *cptGroups;
}
@property (nonatomic, retain) NSString *taxonomyCode;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *data;
@property (nonatomic, retain) NSArray *cptGroups;

+ (id) initSuperbillWithResultSet:(FMResultSet*)resultSet;

@end


