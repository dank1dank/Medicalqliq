//
//  FavoriteContactDBObject.m
//  qliqConnect
//
//  Created by Paul Bar on 12/12/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import "FavoriteContactDBObject.h"
#import "DBUtil.h"

@implementation FavoriteContactDBObject

@synthesize entry_id = entry_id;
@synthesize contact_type = contact_type;
@synthesize contact_id = contact_id;


-(id) init
{
    self = [super init];
    if(self)
    {
        entry_id = 0;
        self.contact_type = [NSNumber numberWithInt:0];
        self.contact_id = @"";
    }
    return self;
}


-(id) initWithEntryId:(NSInteger)entryId
{
    self = [self init];
    if(self)
    {
        entry_id = entryId;
    }
    return self;
}

-(id) initWithResultSet:(FMResultSet*)resultSet
{
    self = [super init];
    if(self)
    {
        entry_id = [resultSet intForColumn:@"entry_id"];
        self.contact_type = [NSNumber numberWithInt:[resultSet intForColumn:@"contact_type"]];
        self.contact_id = [resultSet stringForColumn:@"contact_id"];
    }
    return self;
}

-(void) dealloc
{
    [contact_type release];
    [contact_id release];
    [super dealloc];
}


-(BOOL) save
{
    NSString *selectQuery = @"SELECT "
    "contact_type as contact_type, "
    "contact_id as contact_id "
    "FROM favorite_contacts "
    "WHERE id = ?";
    
    NSString *updateQuery = @"UPDATE "
    "favorite_contacts SET "
    "contact_type = ? ,"
    "contact_id = ? "
    "WHERE id = ?";
    
    NSString *insertQuery = @"INSERT INTO "
    "favorite_contacts (contact_type, contact_id) "
    "VALUES (?,?)";

    __block BOOL result = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *result_set = [db executeQuery:selectQuery, entry_id];
        
       
        if([result_set next])
        {
            //update
            result = [db executeUpdate:updateQuery,self.contact_type, self.contact_id, entry_id];
        }
        else
        {
            //insert
            result = [db executeUpdate:insertQuery,self.contact_type, self.contact_id];
            if(result)
            {
                entry_id = [db lastInsertRowId];
            }
        }
        [result_set close];
    }];
    return result;
}

-(BOOL) remove
{
    __block BOOL ret = NO;
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        ret= [db executeUpdate:@"DELETE FROM favorite_contacts WHERE contact_id = ?",
              self.contact_id];
    }];
    return ret;
}

+(NSArray*) getAllFavoriteContactsDbObjects
{
    NSString *selectQuery = @"SELECT "
    "id as entry_id, "
    "contact_type as contact_type, "
    "contact_id as contact_id "
    "FROM favorite_contacts ";
    
    // As it is leaking about 1 byte per call.
    __block NSMutableArray *mutableRez = [NSMutableArray array];
    [[DBUtil sharedQueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:selectQuery];
        while([resultSet next])
        {
            FavoriteContactDBObject *obj = [[FavoriteContactDBObject alloc] initWithResultSet:resultSet];
            [mutableRez addObject:obj];
            [obj release];
        }
        [resultSet close];
        
    }];
    return mutableRez;
}

@end
