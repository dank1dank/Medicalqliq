//
//  SuperbillService.m
//  qliq
//
//  Created by Paul Bar on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SuperbillDbService.h"
#import "Superbill.h"

@interface SuperbillDbService()

-(BOOL) superbillExists:(Superbill*)superbill;
-(BOOL) insertSuperbill:(Superbill*)superbill;
-(BOOL) updateSuperbill:(Superbill*)superbill;

@end

@implementation SuperbillDbService

-(BOOL) saveSuperbill:(Superbill *)superbill
{
    BOOL rez = NO;
    if([self superbillExists:superbill])
    {
        rez = [self updateSuperbill:superbill];
    }
    else
    {
        rez = [self insertSuperbill:superbill];
    }
    return rez;
}

-(Superbill*) getSuperbill:(NSString *)taxonomyCode
{
    Superbill *rez = nil;
    
    NSString *selectQuery = @""
    " SELECT * FROM superbill WHERE taxonomy_code = ?";
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,taxonomyCode];
    
    if([rs next])
    {
        rez = [Superbill initSuperbillWithResultSet:rs];
    }
    
    return rez;
}
#pragma mark -
#pragma mark Private

-(BOOL)superbillExists:(Superbill *)superbill
{
    BOOL rez = NO;
    
    NSString *selectQuery = @""
    "SELECT * FROM superbill WHERE taxonomy_code = ?";
	NSLog(@"taxonomy_code: %@",superbill.taxonomyCode);
    
    FMResultSet *rs = [self.db executeQuery:selectQuery,superbill.taxonomyCode];
    
    if([rs next])
    {
        rez = YES;
    }
    
    return rez;
}

-(BOOL)insertSuperbill:(Superbill *)superbill
{
    NSString *insertQuery = @""
    " INSERT INTO superbill (taxonomy_code, name, data) VALUES (?,?,?)";
    
   [self.db beginTransaction];
    
    BOOL rez = [self.db executeUpdate:insertQuery, 
                superbill.taxonomyCode,
				superbill.name,
				superbill.data];
    
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

-(BOOL) updateSuperbill:(Superbill *)superbill
{
    NSString *updateRequest = @""
    "UPDATE superbill SET "
    " name = ?, "
    " data = ? "
    " WHERE taxonomy_code = ? ";
    
   [self.db beginTransaction];
    
    BOOL rez = [self.db executeUpdate:updateRequest,
                superbill.name,
                superbill.data,
                superbill.taxonomyCode];
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
