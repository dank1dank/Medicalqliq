//
//  Metadata.h
//  CCiPhoneApp
//
//  Created by Adam Sowa on 11/25/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Metadata : NSObject {
    NSString *uuid;
    NSString *rev;
    NSString *author;
    unsigned int seq;
    BOOL isRevisionDirty;
    NSUInteger version;
}
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSString *rev;
@property (nonatomic, retain) NSString *author;
@property (nonatomic, readwrite) unsigned int seq;
@property (nonatomic, readwrite) BOOL isRevisionDirty;
@property (nonatomic, readwrite) NSUInteger version;

- (NSString *) toJson;
- (NSMutableDictionary *) toDict;
+ (id) metadataFromDict:(NSDictionary *)dict;

// Default author is also used as machine ID when generating UUID
+ (void) setDefaultAuthor:(NSString *)author;
+ (NSString *) defaultAuthor;
+ (NSString *) generateUuid;
+ (Metadata *) createNew;

// Parses a rev string like 3-76ae13fe08 and returns 3
+ (NSUInteger) revisionNumberFromString:(NSString *)rev;

@end
