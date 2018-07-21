//
//  Metadata.m
//  CCiPhoneApp
//
//  Created by Adam Sowa on 11/25/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#import "Metadata.h"
#import "MetadataSchema.h"
#import "StringMd5.h"
#import "Helper.h"

@implementation Metadata
@synthesize uuid, rev, author, seq, isRevisionDirty, version;

static NSString *s_defaultAuthor;

- (id) init
{
    if (self = [super init]) {
        seq = 0;
    }
    return self;
}

- (NSString *) toJson
{
    NSString *json = [NSString stringWithFormat:@"{\"uuid\": \"%@\", \"author\": \"%@\", \"rev\": \"%@\", \"seq\": %u",
                      uuid, author, rev, seq];
    return json;
}

+ (id) metadataFromDict:(NSDictionary *)dict
{
	Metadata *metadata = [[Metadata alloc] init];
	metadata.uuid = [dict objectForKey:METADATA_UUID];
  	metadata.rev = [dict objectForKey:METADATA_REV];
    metadata.author = [dict objectForKey:METADATA_AUTHOR];
    NSNumber *seqNumber = [dict objectForKey:METADATA_SEQ];
    if (seqNumber) {
        metadata.seq = [seqNumber unsignedIntValue];
    }
    
    NSNumber *verNumber = [dict objectForKey:METADATA_VERSION];
    if (verNumber) {
        metadata.version = [verNumber unsignedIntValue];
    }
    
    metadata.isRevisionDirty = NO;
    return metadata;
}

- (NSMutableDictionary *) toDict
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:uuid forKey:METADATA_UUID];
    [dict setObject:author forKey:METADATA_AUTHOR];
    [dict setObject:[NSNumber numberWithUnsignedInt:seq] forKey:METADATA_SEQ];
    
    if (rev)
        [dict setObject:rev forKey:METADATA_REV];
    
    if (version)
        [dict setObject:[NSNumber numberWithUnsignedInteger:version] forKey:METADATA_VERSION];
    
    return dict;
}

+ (NSString *) generateUuid
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return [(__bridge_transfer NSString *)string lowercaseString];
}

char *alloc_uuid_for_qxlib()
{
    NSString *uuid = [Metadata generateUuid];
    const char *raw = [uuid UTF8String];
    char *buffer = malloc(uuid.length + 1);
    strcpy(buffer, raw);
    return buffer;
}

+ (Metadata *) createNew
{
    Metadata *ret = [[Metadata alloc] init];
    ret.uuid = [self generateUuid];
    ret.seq = 1;
    ret.author = [Metadata defaultAuthor];
    return ret;
}

+ (void) setDefaultAuthor:(NSString *)author
{
    s_defaultAuthor = author;
}

+ (NSString *) defaultAuthor
{
    if (s_defaultAuthor == nil)
    {
        [Metadata setDefaultAuthor:[Helper getMyQliqId]];
    }
    return s_defaultAuthor;
}

+ (NSUInteger) revisionNumberFromString:(NSString *)rev
{
    NSUInteger ret = 0;
    NSArray *array = [rev componentsSeparatedByString:@"-"];
    if ([array count] > 0) {
        rev = [array objectAtIndex:0];
        ret = [rev intValue];
    }
    return ret;
}

@end
