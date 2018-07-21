//
//  FavoriteContactDBObject.h
//  qliqConnect
//
//  Created by Paul Bar on 12/12/11.
//  Copyright (c) 2011 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMResultSet;

@interface FavoriteContactDBObject : NSObject
{
    NSInteger entry_id;
}

-(id) initWithEntryId:(NSInteger) entryId;
-(BOOL) save;
-(BOOL) remove;
+(NSArray*) getAllFavoriteContactsDbObjects;
-(id) initWithResultSet:(FMResultSet*)resultSet;

@property (nonatomic, readonly) NSInteger entry_id;
@property (nonatomic, retain) NSNumber *contact_type;
@property (nonatomic, retain) NSString *contact_id;

@end
