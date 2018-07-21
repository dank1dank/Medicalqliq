//
//  ReferringProviderService.m
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ReferringProviderDbService.h"
#import "ReferringProvider.h"

@interface ReferringProviderDbService()

-(BOOL) referringProviderExists:(ReferringProvider*)referringProvider;
-(BOOL) insertReferringProvider:(ReferringProvider*)referringProvider;
-(BOOL) updateReferringProvider:(ReferringProvider*)referringProvider;

@end

@implementation ReferringProviderDbService

-(BOOL) saveReferringProvider:(ReferringProvider *)referringProvider
{
    BOOL rez = NO;
    if([self referringProviderExists:referringProvider])
    {
        rez = [self updateReferringProvider:referringProvider];
    }
    else
    {
        rez = [self insertReferringProvider:referringProvider];
    }
    return rez;
}

-(ReferringProvider*) getReferringProviderWithNpi:(NSNumber *)npi
{
    ReferringProvider *rez = nil;
    
    NSString *selectQuery = @""
    " SELECT * FROM referring_provider WHERE npi = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,npi];
    
    if([rs next])
    {
		ReferringProvider *referringProvider = [[ReferringProvider alloc] init];
        rez = [referringProvider initReferringProviderWithResultSet:rs];
    }
    
    return rez;
}

-(NSArray*) getReferringProviders
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] init];
    
    NSString *selectQuery = @""
    @"SELECT * FROM referring_provider";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery];
    
    while ([rs next])
    {
		ReferringProvider *referringProvider = [[ReferringProvider alloc] init];
        [mutableRez addObject:[referringProvider initReferringProviderWithResultSet:rs]];
    }
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    
    return rez;
}

#pragma mark -
#pragma mark Private

-(BOOL)referringProviderExists:(ReferringProvider *)referringProvider
{
    BOOL rez = NO;
    
    NSString *selectQuery = @""
    "SELECT * FROM referring_provider WHERE npi = ?";
	NSLog(@"npi: %f",referringProvider.npi);
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,[NSNumber numberWithDouble:referringProvider.npi]];
    
    if([rs next])
    {
        rez = YES;
    }
    
    return rez;
}

-(BOOL)insertReferringProvider:(ReferringProvider *)referringProvider
{
    NSString *insertQuery = @""
    " INSERT INTO referring_provider (npi, first_name, last_name, middle_name, prefix, suffix, credentials, address, city, state, zip, phone, mobile, fax, email, taxonomy_code, sip_uri) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
    
    [self.db beginTransaction];
    
    BOOL rez = [self.db executeUpdate:insertQuery, 
                [NSNumber numberWithDouble:referringProvider.npi],
				referringProvider.firstName,
				referringProvider.lastName,
				referringProvider.middleName,
				referringProvider.prefix,
				referringProvider.suffix,
				referringProvider.credentials,
                referringProvider.address,
                referringProvider.city,
                referringProvider.state,
                referringProvider.zip,
                referringProvider.phone,
                referringProvider.mobile,
                referringProvider.fax,
                referringProvider.email,
				referringProvider.taxonomyCode,
				referringProvider.sipUri];
    
    if(!rez)
    {
        [self.db rollback];
    }
    else
    {
       [self.db commit];
    }
    
    return rez;
}

-(BOOL) updateReferringProvider:(ReferringProvider *)referringProvider
{
    NSString *updateRequest = @""
    "UPDATE referring_provider SET "
    " first_name = ?, "
    " last_name = ?, "
    " middle_name = ?, "
    " prefix = ?, "
    " suffix = ?, "
    " credentials = ?, "
    " address = ?, "
    " city = ?, "
    " state = ?, "
    " zip = ?, "
    " phone = ?, "
    " mobile = ?, "
    " fax = ?, "
    " email = ?, "
    " taxonomy_code = ?, "
	" sip_uri = ? "
    " WHERE npi = ? ";
    
    [self.db beginTransaction];
    
    BOOL rez = [self.db executeUpdate:updateRequest,
                referringProvider.firstName,
                referringProvider.lastName,
                referringProvider.middleName,
                referringProvider.prefix,
                referringProvider.suffix,
                referringProvider.credentials,
                referringProvider.address,
                referringProvider.city,
                referringProvider.state,
                referringProvider.zip,
                referringProvider.phone,
                referringProvider.mobile,
                referringProvider.fax,
                referringProvider.email,
				referringProvider.taxonomyCode,
				referringProvider.sipUri,
                [NSNumber numberWithDouble:referringProvider.npi]];
    if(!rez)
    {
       [self.db rollback];
    }
    else
    {
       [self.db commit];
    }
    
    return rez;
}

@end
