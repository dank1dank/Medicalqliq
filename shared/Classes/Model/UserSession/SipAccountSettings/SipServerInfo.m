//
//  SipServerInfo.m
//  qliq
//
//  Created by Paul Bar on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SipServerInfo.h"
#import "DBUtil.h"
#import "Helper.h"

@implementation SipServerInfo

@synthesize sipServerId;
@synthesize fqdn;
@synthesize port;
@synthesize transport;
@synthesize multiDevice;

+ (NSMutableDictionary *) getSipServerInfo
{
	__block NSMutableDictionary *sipServerDict = [[[NSMutableDictionary alloc] init] autorelease];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectSipServerInfoQuery = @"SELECT "
        " id as sip_server_id, "
        " fqdn, "
        " port, "
        " transport, "
        " multi_device "
        " FROM sip_server_info ";
        
        FMResultSet *sip_server_rs = [db executeQuery:selectSipServerInfoQuery];
        while ([sip_server_rs next])
        {
            NSInteger primaryKey = [sip_server_rs intForColumn:@"sip_server_id"];
            SipServerInfo *sipServerObj = [[SipServerInfo alloc] initWithPrimaryKey:primaryKey];
            sipServerObj.fqdn = [sip_server_rs stringForColumn:@"fqdn"];
            sipServerObj.port = [sip_server_rs intForColumn:@"port"];
            sipServerObj.transport = [sip_server_rs stringForColumn:@"transport"];
            sipServerObj.multiDevice = [sip_server_rs boolForColumn:@"multi_device"];
            [sipServerDict setObject:sipServerObj forKey:sipServerObj.fqdn];
            [sipServerObj release];
        }
        [sip_server_rs close];
    }];
	return sipServerDict;
}

+ (BOOL) addSipServerInfo:(SipServerInfo *) sipserver
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        NSString *selectSipServerInfoQuery = @"SELECT "
        " id as sip_server_id "
        " FROM sip_server_info "
        " WHERE fqdn = ?";
        
        FMResultSet *sip_server_rs = [db executeQuery:selectSipServerInfoQuery, sipserver.fqdn];
        BOOL recordFound = NO;
        if ([sip_server_rs next]) {
            recordFound = YES;
        }
        [sip_server_rs close];
       
        
        if (recordFound) {
            ret = [db executeUpdate:@"UPDATE sip_server_info set port=?,transport=?,multi_device=?,last_updated_user=?,last_updated=? WHERE fqdn=? ",
                 [NSNumber numberWithInteger:sipserver.port],
                 sipserver.transport,
                 [NSNumber numberWithBool:sipserver.multiDevice],
                 [Helper getMyQliqId],
                 [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]],
                   sipserver.fqdn];
        } else {
            ret = [db executeUpdate:@"INSERT INTO sip_server_info (fqdn,port,transport,multi_device,last_updated_user, last_updated) VALUES(?,?,?,?,?,?)",
                 sipserver.fqdn,
                 [NSNumber numberWithInteger:sipserver.port],
                 sipserver.transport,
                 [NSNumber numberWithBool:sipserver.multiDevice],
                 [Helper getMyQliqId],
                  [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]]];
        }
    }];
    return ret;
}

+ (BOOL) deleteAllSipServerInfo
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret = [db executeUpdate:@"DELETE FROM sip_server_info"];
    }];
    return ret;
}

+ (SipServerInfo *) getRecentSipServerInfo
{
    return [[[self getSipServerInfo] objectEnumerator] nextObject];
}

- (id) initWithPrimaryKey:(NSInteger) pk
{    
    if (self = [super init])
    {
		sipServerId = pk;
	}
    return self;
}

-(void) dealloc
{
    [transport release];
    [super dealloc];
}

#pragma mark -
#pragma mark serialization

static NSString *key_sipServerId = @"key_sipServerId";
static NSString *key_fqdn = @"key_fqdn";
static NSString *key_port = @"key_port";
static NSString *key_transport = @"key_transport";
static NSString *key_multiDevice = @"key_multiDevice";

-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSNumber numberWithInteger:self.sipServerId] forKey:key_sipServerId];
    [aCoder encodeObject:self.fqdn forKey:key_fqdn];
    [aCoder encodeObject:[NSNumber numberWithInteger:self.port] forKey:key_port];
    [aCoder encodeObject:self.transport forKey:key_transport];
    [aCoder encodeObject:[NSNumber numberWithBool:self.multiDevice] forKey:key_multiDevice];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self)
    {
        sipServerId = [[aDecoder decodeObjectForKey:key_sipServerId] intValue];
        self.fqdn = [aDecoder decodeObjectForKey:key_fqdn];
        self.port = [[aDecoder decodeObjectForKey:key_port] intValue];
        self.transport = [aDecoder decodeObjectForKey:key_transport];
        self.multiDevice = [[aDecoder decodeObjectForKey:key_multiDevice] boolValue];
    }
    return self;
}

@end
