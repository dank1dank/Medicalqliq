//
//  SipServerInfo.h
//  qliq
//
//  Created by Paul Bar on 2/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SipServerInfo : NSObject <NSCoding>
{ 
	NSInteger sipServerId;
	NSString *fqdn;
	NSInteger port;
	NSString *transport;
    BOOL multiDevice;
}

@property (nonatomic, readonly) NSInteger sipServerId;
@property (nonatomic, retain) NSString  *fqdn;
@property (nonatomic, readwrite) NSInteger port;
@property (nonatomic, retain) NSString  *transport;
@property (nonatomic, readwrite) BOOL multiDevice;

//Static methods.
+ (NSMutableDictionary *) getSipServerInfo;
+ (BOOL) addSipServerInfo:(SipServerInfo *) sipserver;
+ (BOOL) deleteAllSipServerInfo;
+ (SipServerInfo *) getRecentSipServerInfo;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;
@end