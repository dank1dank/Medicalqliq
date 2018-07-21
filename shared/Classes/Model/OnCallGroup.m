//
//  OnCallGroup.m
//  qliq
//
//  Created by Adam on 10/08/15.
//
//

#import "OnCallGroup.h"
#import "GetGroupInfoService.h"
#import "QliqUserDBService.h"
#import "KeyValueDBService.h"
#import "JSONKit.h"
#import "NSDate-Utilities.h"
#import "ABTimeCounter.h"

static const NSTimeInterval SECONDS_PER_DAY = 86400;
static NSArray *s_groups;

#define DB_KEY @"oncall_group_list"

@implementation OnCallGroup

+ (BOOL) date:(NSDate *)date isBetweenDate:(NSDate *)beginDate andDate:(NSDate *)endDate
{
    if ([date compare:beginDate] == NSOrderedAscending)
        return NO;
    
    if ([date compare:endDate] == NSOrderedDescending)
        return NO;
    
    return YES;
}

///TODO: need implement
+ (NSArray *)activeOnCallGroups {
    return nil;
}

// Sets date part to 1970-1-1. Used when we want to compare only time parts of 2 NSDate objects
+ (NSDate *) setDateComponentsTo1970:(NSDate *)date
{
    ///TODO: why get nil?
    if (!date){
        return nil;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    [dateComponents setYear:1970];
    [dateComponents setMonth:1];
    [dateComponents setDay:1];
    return [calendar dateFromComponents:dateComponents];
}

// Sets time part to 00:00:00. Used when we want to compare only date parts of 2 NSDate objects
+ (NSDate *) setDateComponentsToMidnight:(NSDate *)date
{
    ///TODO: why get nil?
    if (!date){
        return nil;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    [dateComponents setHour:0];
    [dateComponents setMinute:0];
    [dateComponents setSecond:0];
    return [calendar dateFromComponents:dateComponents];
}

// Sets time part to 00:00:00. Used when we want to compare only date parts of 2 NSDate objects
+ (NSDate *) skipTimeComponent:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger comps = (NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear);
    NSDateComponents *dateComponents = [calendar components:comps fromDate: date];
    return [calendar dateFromComponents:dateComponents];
}

+ (NSDate *) skipDateComponent:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger comps = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
    NSDateComponents *dateComponents = [calendar components:comps fromDate: date];
    return [calendar dateFromComponents:dateComponents];
}

+ (BOOL) isMidnight:(NSDate *)date withCalendar:(NSCalendar *)calendar
{
    NSInteger comps = (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
    NSDateComponents *dateComponents = [calendar components:comps fromDate: date];
    NSInteger hour = [dateComponents hour];
    NSInteger minute = [dateComponents minute];
    return (hour == 0 && minute == 0);
}

+ (BOOL) isMidnight:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return [self isMidnight:date withCalendar:calendar];
}

+ (NSDate *) stringToDateOnly:(NSString *)str
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"yyyy-MM-dd"];
    NSDate *ret = [format dateFromString:str];
    return ret;
}

+ (NSDate *) stringToTimeOnly:(NSString *)str
{
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"HH:mm"];
    NSDate *ret = [format dateFromString:str];
    return ret;
}

- (id) initWithQliqGroup:(QliqGroup *)group
{
    self = [super init];
    if (self) {
        self.qliqId = group.qliqId;
        self.parentQliqId = group.parentQliqId;
        self.contactId = group.contactId;
        self.name = group.name;
        self.acronym = group.acronym;
        self.address = group.address;
        self.city = group.city;
        self.state = group.state;
        self.zip = group.zip;
        self.phone = group.phone;
        self.fax = group.fax;
        self.npi = group.npi;
        self.taxonomyCode = group.taxonomyCode;
        self.accessType = group.accessType;
        self.locked = group.locked;
        self.belongs = group.belongs;
        self.openMembership = group.openMembership;
        self.canMessage = group.canMessage;
        self.canBroadcast = group.canBroadcast;
        
        self.shifts = [[NSMutableArray alloc] init];
        self.users = [[NSMutableArray alloc] init];
        self.notesPerMember = [[NSMutableArray alloc] init];
        
        // Krishna 3/7/2017
        // Store Dictionary of the Shifts and process the dictionary when the Details of
        // OnCall Group is needed. This is to speed up the Loading of OnCall Groups at
        // The List level
        self.shifts_json = nil;
    }
    return self;
}

- (void) loadOnCallShiftsFromJson
{
    // This check will ensure that it is loaded only once.
    if ([self.shifts count] == 0) {
        for (NSDictionary *shiftDict in self.shifts_json) {
            OnCallShift *shift = [OnCallShift fromDict:shiftDict];
            if (shift != nil) {
                [self.shifts addObject:shift];
            }
        }
    }
}

- (NSArray *) membersWithHoursForDate:(NSDate *) date withCalendar:(NSCalendar *)calendar
{
    NSMutableArray *ret = [NSMutableArray new];
    NSArray *shifts = [self shiftsForDate:date withCalendar:calendar];
    if (shifts.count > 0) {
        // For all primary and backup members load existing QliqUsers into 'users' property
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"hh:mma"];
        
        NSDate *nowDate = [NSDate date];
        BOOL isToday = [date isEqualToDateIgnoringTime:nowDate];
        
        for (OnCallShift *shift in shifts) {
            NSString *shiftHours = [NSString stringWithFormat:@"%@ %@-%@ %@", [OnCallDay dayOfWeekToString:shift.currentDay.dayOfWeek], [formatter stringFromDate:shift.currentDay.startTime], [OnCallDay dayOfWeekToString:shift.currentDay.endDayOfWeek], [formatter stringFromDate:shift.currentDay.endTime]];
            // Replace AM/PM with a/p
            shiftHours = [shiftHours stringByReplacingOccurrencesOfString:@"AM" withString:@"a"];
            shiftHours = [shiftHours stringByReplacingOccurrencesOfString:@"PM" withString:@"p"];
            
            if (isToday) {
                BOOL compareEndTime = NO;
                if (shift.currentDay.isOvernight == NO) {
                    if (shift.currentDay.dayOfWeek != shift.currentDay.endDayOfWeek && [OnCallGroup isMidnight:shift.currentDay.endTime]) {
                        // That must be shift ending at midnight, no need to compare time
                    } else {
                        compareEndTime = YES;
                    }
                } else {
                    if (shift.currentDay.endDayOfWeek == nowDate.weekday) {
                        compareEndTime = YES;
                    }
                }
                
                if (compareEndTime) {
                    if ([shift.currentDay.endTime compareTimeIgnoreDate:nowDate isStartDate:nil] == NSOrderedAscending) {
                        //Do not show past shifts
//                        continue;
                    }
                }
            }
            
            if ([shift.primaryMembers count] > 0) {
                for (NSString *qliqId in shift.primaryMembers) {
                    QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:qliqId];
                    if (user != nil) {
                        user.specialty = shiftHours;
                        user.taxonomyCode = @"primary";
                        QliqUserWithOnCallHours *uh = [QliqUserWithOnCallHours new];
                        uh.dayOfWeek = shift.currentDay.dayOfWeek;
                        uh.endDayOfWeek = shift.currentDay.endDayOfWeek;
                        uh.startTime = shift.currentDay.startTime;
                        uh.endTime = shift.currentDay.endTime;
                        uh.isOvernight = shift.currentDay.isOvernight;
                        uh.user = user;
                        uh.isBackup = NO;
                        [ret addObject:uh];
                    }
                }
            }
            
            if ([shift.backupMembers count] > 0) {
                for (NSString *qliqId in shift.backupMembers) {
                    QliqUser *user = [[QliqUserDBService sharedService] getUserWithId:qliqId];
                    if (user != nil) {
                        user.specialty = shiftHours;
                        user.taxonomyCode = @"backup";
                        QliqUserWithOnCallHours *uh = [QliqUserWithOnCallHours new];
                        uh.dayOfWeek = shift.currentDay.dayOfWeek;
                        uh.endDayOfWeek = shift.currentDay.endDayOfWeek;
                        uh.startTime = shift.currentDay.startTime;
                        uh.endTime = shift.currentDay.endTime;
                        uh.isOvernight = shift.currentDay.isOvernight;
                        uh.user = user;
                        uh.isBackup = YES;
                        [ret addObject:uh];
                    }
                }
            }
        }
        
        //NSDate *nowTime = [OnCallGroup skipDateComponent:[NSDate date]];
        
        [ret sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            
            QliqUserWithOnCallHours *a = (QliqUserWithOnCallHours *)obj1;
            QliqUserWithOnCallHours *b = (QliqUserWithOnCallHours *)obj2;
            NSComparisonResult result;
            
            // TODO: sort active first, for this we need to compare day of week and then only time in range
            BOOL isActiveA = NO, isActiveB = NO;
            
            if (isToday) {
                isActiveA = [a isActiveOnDate:date];
                isActiveB = [b isActiveOnDate:date];
            }
            
            if (isActiveA && !isActiveB) {
                result = NSOrderedAscending;
            } else if (!isActiveA && isActiveB) {
                result = NSOrderedDescending;
            } else if (a.dayOfWeek < b.dayOfWeek) {
                result = NSOrderedAscending;
            } else if (a.dayOfWeek > b.dayOfWeek) {
                result = NSOrderedDescending;
            } else {
                result = [a.startTime compare:b.startTime];
                if (result == NSOrderedSame) {
                    result = [a.startTime compare:b.startTime];
                    if (result == NSOrderedSame) {
                        if (!a.isBackup && b.isBackup) {
                            result = NSOrderedAscending;
                        } else if (!a.isBackup && b.isBackup) {
                            result = NSOrderedDescending;
                        } else {
                            result = [a.user.displayName compare:b.user.displayName];
                            result = NSOrderedDescending; 
                        }
                    }
                }
            }
            return result;
        }];
    }
    return ret;
}

- (NSArray *) notesForDate:(NSDate *) nowDate
{
    // make sure nowDate has only date part (no time)
    nowDate = [OnCallGroup skipTimeComponent:nowDate];
    
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    
    for (OnCallShift *shift in self.shifts) {
        if ([OnCallGroup date:nowDate isBetweenDate:shift.startDate andDate:shift.endDate]) {
            
            for (OnCallOverride *override in shift.overrides) {
                if ([override.date compare:nowDate] == NSOrderedSame) {
                    if (override.isEnabled) {
                        if (override.notes.length > 0) {
                            [ret addObject:override.notes];
                        }
                    }
                }
            }
        }
    }
    
    return ret;
}

- (void) appendShiftsForDate:(NSDate *) nowDate withCalendar:(NSCalendar *)calendar overnightOnly:(BOOL)onlyOvernight toArray:(NSMutableArray *)ret
{
    // make sure nowDate has only date part (no time)
    nowDate = [OnCallGroup skipTimeComponent:nowDate];
    
    NSDateComponents *comps = [calendar components:NSCalendarUnitWeekday fromDate:nowDate];
    NSInteger weekday = [comps weekday];
    
    for (OnCallShift *shift in self.shifts) {
        if ([OnCallGroup date:nowDate isBetweenDate:shift.startDate andDate:shift.endDate]) {
            
            BOOL hasOverride = NO;
            for (OnCallOverride *override in shift.overrides) {
                if ([override.date compare:nowDate] == NSOrderedSame) {
                    hasOverride = YES;
                    if (override.isEnabled) {
                        OnCallShift *s = [shift mutableCopy];
                        OnCallDay *day = [override toDay];
                        s.currentDay = day;
                        BOOL endsOnMidnight = [OnCallGroup isMidnight:day.endTime];
                        if (!onlyOvernight || (day.isOvernight && !endsOnMidnight)) {
                            day.dayOfWeek = weekday;
                            if (day.isOvernight) {
                                // End time is 1 day later
                                day.endDayOfWeek = [OnCallDay incrementDayOfWeek:day.dayOfWeek];
                                if (endsOnMidnight) {
                                    day.isOvernight = NO;
                                }
                            } else {
                                day.endDayOfWeek = day.dayOfWeek;
                            }
                            s.primaryMembers = [override.primaryMembers mutableCopy];
                            s.backupMembers = [override.backupMembers mutableCopy];
                            [ret addObject:s];
                        }
                    }
                    break;
                }
            }
            
            if (!hasOverride) {
                for (OnCallDay *day in shift.days) {
                    if (day.dayOfWeek == weekday) {
                        if (day.isEnabled) {
                            if (!onlyOvernight || day.isOvernight) {
                                OnCallShift *s = [shift mutableCopy];
                                s.currentDay = [day mutableCopy];
                                [ret addObject:s];
                            }
                        }
                        break;
                    }
                }
            }
        }
    }
}

- (NSArray *) shiftsForDate:(NSDate *) nowDate withCalendar:(NSCalendar *)calendar
{
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    [self appendShiftsForDate:nowDate withCalendar:calendar overnightOnly:NO toArray:ret];
    
    NSDate *prevDate = [nowDate dateByAddingDays:-1];
    [self appendShiftsForDate:prevDate withCalendar:calendar overnightOnly:YES toArray:ret];
    
    return ret;
}

- (OnCallShift *) shiftForDate:(NSDate *) nowDate withCalendar:(NSCalendar *)calendar
{
    NSArray *shifts = [self shiftsForDate:nowDate withCalendar:calendar];
    if (shifts.count > 0) {
        return [shifts objectAtIndex:0];
    } else {
        return nil;
    }
}

- (NSArray *)getOnlyContacts
{
    return self.users;
}

- (OnCallMemberNotes *)getNotesForUser:(QliqUser *)user {
    OnCallMemberNotes *memberNotes = nil;
    
    for (OnCallMemberNotes *notesForMember in self.notesPerMember) {
        if ([notesForMember.memberQliqId isEqualToString:user.qliqId]) {
            memberNotes = notesForMember;
            break;
        }
    }
    
    return memberNotes;
}

+ (NSArray *) fromJsonArray:(NSArray *)json
{
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (NSDictionary *groupDict in json) {
        OnCallGroup *group = [OnCallGroup fromDict:groupDict];
        if (group != nil) {
            [ret addObject:group];
        } else {
            DDLogError(@"Nil onCall Group");
        }
    }
    return ret;
}

+ (OnCallGroup *) fromDict:(NSDictionary *)dict
{
    OnCallGroup *group = [[OnCallGroup alloc] initWithQliqGroup:[GetGroupInfoService parseGroupJson:dict andSaveInDb:NO]];
    
    group.shifts_json = [dict[@"shifts"] copy];
    // Also remove all Objects to make sure if there are shifts built previously
    // They will be erased. This takes care of User views an OnCall Group and there is
    // a change for the shifts and the OnCall Group gets rebuilt.
    // See loadShiftFromJson method
    //
    [group.shifts removeAllObjects];
    
    // Krishn 3/7/2017
    // Do not Process Shifts here. Just store the Dictionary. Process the Shifts When User Touches the
    // On Call Group to Load Calendar of the OnCall Group
#if 0
    for (NSDictionary *shiftDict in dict[@"shifts"]) {
        OnCallShift *shift = [OnCallShift fromDict:shiftDict];
        if (shift != nil) {
            [group.shifts addObject:shift];
        }
    }
#endif
    
    for (NSDictionary *notesDict in dict[@"member_notes"]) {
        OnCallMemberNotes *memberNotes = [OnCallMemberNotes fromDict:notesDict];
        if (memberNotes != nil) {
            [group.notesPerMember addObject:memberNotes];
        }
    }
    
    // Need to assign this so that the epoch is updated and used in the subsequent
    // Calls. The server will know which ones to update and which ones should not be.
    //
    NSNumber *lastUpdated = @([dict[@"last_updated_epoch"] unsignedIntegerValue]);
    group.lastUpdated = [lastUpdated unsignedIntegerValue];
    
    return group;
}

+ (void) setOnCallGroups:(NSArray *)groups
{
    s_groups = nil;
    s_groups = groups;
}

+ (NSArray *) onCallGroups
{
    if (s_groups == nil) {
        [self loadFromDatabase];
    }
    return s_groups;
}

+ (NSUInteger) lastUpdated:(NSString *)qliqId
{
    for (OnCallGroup *g in [self onCallGroups]) {
        if ([g.qliqId isEqualToString:qliqId]) {
            return g.lastUpdated;
        }
    }
    return 0;
}

+ (NSArray *) onCallGroupsActiveForNowDate:(NSCalendar *)calendar
{
    NSDate *nowDate = [NSDate date];
    return [self onCallGroupsActiveForDate:nowDate withCalendar:calendar];
}

+ (NSArray *) onCallGroupsActiveForDate:(NSDate *)date withCalendar:(NSCalendar *)calendar
{
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"hh:mma"];
    
    for (OnCallGroup *group in s_groups) {
        OnCallShift *shift = [group shiftForDate:date withCalendar:calendar];
        [group.users removeAllObjects];
        
        if ([shift.users count] > 0) {
            group.users  = [shift.users mutableCopy];
            [ret addObject:group];
        }
    }
    return ret;
}

+ (BOOL) hasConfigInDatabase
{
    return [KeyValueDBService exists:DB_KEY];
}

+ (BOOL) saveToDatabaseJson:(NSString *)json
{
    return [KeyValueDBService insertOrUpdate:DB_KEY withValue:json];
}

+ (BOOL) saveToDatabaseAndUpdateCache:(NSArray *)jsonArray
{
    NSString *jsonString = [jsonArray JSONString];
   
    if ([self saveToDatabaseJson:jsonString]) {
        NSArray *onCallGroups = [self fromJsonArray:jsonArray];
        [self setOnCallGroups:onCallGroups];
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *) loadFromDatabase
{
    DDLogSupport(@"loading OnCallGroups from DB");
    NSArray *groups = nil;
    NSString *json = [KeyValueDBService select:DB_KEY];
    if (json.length > 0) {
        ABTimeCounter *counter = [ABTimeCounter new];
        [counter restart];
        NSStringEncoding dataEncoding = NSUTF8StringEncoding;
        NSError *error=nil;
        NSData *jsonData = [json dataUsingEncoding:dataEncoding];
        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        NSArray *jsonArray = [jsonKitDecoder objectWithData:jsonData error:&error];
        groups = [self fromJsonArray:jsonArray];
        DDLogSupport(@"Time took to load %lu OnCall Groups: %f sec", (unsigned long)[groups count], [counter measuredTime]);
    }
    [self setOnCallGroups:groups];
    return json;
}

+ (NSArray *)loadFromDatabaseJsonArrayOfOnCallGroups
{
    NSArray *jsonArray = nil;
    NSString *json = [KeyValueDBService select:DB_KEY];
    if (json.length > 0) {
        NSStringEncoding dataEncoding = NSUTF8StringEncoding;
        NSError *error=nil;
        NSData *jsonData = [json dataUsingEncoding:dataEncoding];
        JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
        jsonArray = [jsonKitDecoder objectWithData:jsonData error:&error];

    }
    return jsonArray;
}

+ (void) postOnCallGroupsChangedNotification:(NSArray *)changedGroups withNewGroups:(NSArray *)newGroups withDeletedIds:(NSArray *)deletedIds
{
    if (changedGroups == nil) {
        changedGroups = [NSArray new];
    }
    if (newGroups == nil) {
        newGroups = [NSArray new];
    }
    if (deletedIds == nil) {
        deletedIds = [NSArray new];
    }
    
    NSDictionary *userInfo = @{
        kKeyOnCallNewGroups: newGroups,
        kKeyOnCallChangedGroups: changedGroups,
        kKeyOnCallDeletedIds: deletedIds
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:kOnCallGroupsChangedNotification object:nil userInfo:userInfo];
}

+ (NSUInteger) findIndexInArray:(NSArray *)array withKey:(NSString *)key withValue:(NSString *)expectedValue
{
    for (NSUInteger i = 0; i < [array count]; i++) {
        NSDictionary *dict = [array objectAtIndex:i];
        if ([expectedValue isEqualToString: [dict objectForKey:key]]) {
            return i;
        }
    }
    return NSNotFound;
}

+ (void) processSingleGroupJson:(NSDictionary *)newGroupDictionary {
   
    OnCallGroup *newGroup = [OnCallGroup fromDict:newGroupDictionary];
    
    if (newGroup) {
        NSMutableArray *onCallGroupsJsonArray = [NSMutableArray arrayWithArray:[OnCallGroup loadFromDatabaseJsonArrayOfOnCallGroups]];
        NSUInteger index = [self findIndexInArray:onCallGroupsJsonArray withKey:@"qliq_id" withValue:newGroup.qliqId];
        
        NSArray *changedArray = nil;
        NSArray *newArray = nil;

        if (index != NSNotFound) {
            [onCallGroupsJsonArray replaceObjectAtIndex:index withObject:newGroupDictionary];
            changedArray = @[newGroup];
            DDLogSupport(@"OnCallGroup %@ was updated", newGroup.qliqId);
        } else {
            [onCallGroupsJsonArray addObject:newGroupDictionary];
            newArray = @[newGroup];
             DDLogSupport(@"OnCallGroup %@ was added", newGroup.qliqId);
        }
        
        [OnCallGroup saveToDatabaseAndUpdateCache:onCallGroupsJsonArray];
        [self postOnCallGroupsChangedNotification:changedArray withNewGroups:newArray withDeletedIds:nil];
    }
}

+ (BOOL) processAllGroupsJson:(NSArray *)array
{
    NSMutableArray *newGroups = [NSMutableArray new];
    NSMutableArray *changedGroups = [NSMutableArray new];
    NSMutableArray *deletedGroupIds = [NSMutableArray new];
    
    NSMutableArray *previousJsonArray = [NSMutableArray arrayWithArray:[OnCallGroup loadFromDatabaseJsonArrayOfOnCallGroups]];
    for (NSDictionary *groupDict in array) {
        NSString *qliqId = groupDict[@"qliq_id"];
        NSUInteger index = [self findIndexInArray:previousJsonArray withKey:@"qliq_id" withValue:qliqId];
        OnCallGroup *group = [OnCallGroup fromDict:groupDict];
        
        if (index == NSNotFound) {
            [newGroups addObject:group];
        } else {
            [changedGroups addObject:group];
        }
    }
    
    for (NSDictionary *groupDict in previousJsonArray) {
        NSString *qliqId = groupDict[@"qliq_id"];
        NSUInteger index = [self findIndexInArray:array withKey:@"qliq_id" withValue:qliqId];
        if (index == NSNotFound) {
            [deletedGroupIds addObject:qliqId];
        }
    }
    
    [OnCallGroup saveToDatabaseAndUpdateCache:array];
    [self postOnCallGroupsChangedNotification:changedGroups withNewGroups:newGroups withDeletedIds:deletedGroupIds];
    
    return true;
}

+ (BOOL) processBulkJsonUpdate:(NSArray *)array
{
    BOOL anythingChanged = NO;
    NSMutableArray *onCallGroupsJsonArray = [NSMutableArray arrayWithArray:[OnCallGroup loadFromDatabaseJsonArrayOfOnCallGroups]];
    NSUInteger index = NSNotFound;
    
    NSMutableArray *newGroups = [NSMutableArray new];
    NSMutableArray *changedGroups = [NSMutableArray new];
    NSMutableArray *deletedGroupIds = [NSMutableArray new];
    
    for (NSDictionary *groupDict in array) {
        NSString *status = groupDict[@"status"];
        
        if ([@"added" isEqualToString:status] || [@"updated" isEqualToString:status]) {
            OnCallGroup *group = [OnCallGroup fromDict:groupDict];
            index = [self findIndexInArray:onCallGroupsJsonArray withKey:@"qliq_id" withValue:group.qliqId];
            if (index != NSNotFound) {
                [onCallGroupsJsonArray replaceObjectAtIndex:index withObject:groupDict];
                [changedGroups addObject:group];
                DDLogSupport(@"Updated OnCall group %@", group.qliqId);
            } else {
                [onCallGroupsJsonArray addObject:groupDict];
                [newGroups addObject:group];
                DDLogSupport(@"New OnCall group %@", group.qliqId);
            }
            anythingChanged = YES;
            
        } else if ([@"unknown" isEqualToString:status]) {
            NSString *qliqId = groupDict[@"qliq_id"];
            index = [self findIndexInArray:onCallGroupsJsonArray withKey:@"qliq_id" withValue:qliqId];
            if (index != NSNotFound) {
                [onCallGroupsJsonArray removeObjectAtIndex:index];
                [deletedGroupIds addObject:qliqId];
                anythingChanged = YES;
                DDLogSupport(@"Removed OnCall group %@", qliqId);
            }
        } else {
            DDLogError(@"Unexpected status value '%@' in get_oncall_group_updates JSON", status);
        }
    }
    
    if (anythingChanged) {
        [OnCallGroup saveToDatabaseAndUpdateCache:onCallGroupsJsonArray];
        [self postOnCallGroupsChangedNotification:changedGroups withNewGroups:newGroups withDeletedIds:deletedGroupIds];
    }
    
    return anythingChanged;
}

+ (void)deleteOnCallGroupWithQliqId:(NSString *)qliqId {
    
    NSMutableArray *onCallGroupsJsonArray = [NSMutableArray arrayWithArray:[OnCallGroup loadFromDatabaseJsonArrayOfOnCallGroups]];
    NSInteger index = [self findIndexInArray:onCallGroupsJsonArray withKey:@"qliq_id" withValue:qliqId];
    if (index != NSNotFound) {
        [onCallGroupsJsonArray removeObjectAtIndex:index];
        [OnCallGroup saveToDatabaseAndUpdateCache:onCallGroupsJsonArray];
        
        DDLogSupport(@"OnCallGroup %@ was deleted", qliqId);
        [self postOnCallGroupsChangedNotification:nil withNewGroups:nil withDeletedIds:@[qliqId]];
    }
}

@end

@implementation OnCallMemberNotes

- (id) init
{
    self = [super init];
    
    if (self) {
        self.memberQliqId = @"";
        self.notes = [[NSMutableArray alloc] init];
    }
    
    return self;
}

+ (OnCallMemberNotes *) fromDict:(NSDictionary *)dict
{
    OnCallMemberNotes *memberNotes = [[OnCallMemberNotes alloc] init];
    memberNotes.memberQliqId = dict[kKeyMemberQliqId];
   
    for (NSDictionary *noteDict in dict[kKeyNotes]) {
        OnCallNote *onCallNote = [OnCallNote fromDict:noteDict];
        if (onCallNote) {
            [memberNotes.notes addObject:onCallNote];
        }
    }
    return memberNotes;
}

@end

@implementation OnCallNote

- (id) init
{
    self = [super init];
    if (self) {
        self.author = @"";
        self.text = @"";
    }
    return self;
}

+ (OnCallNote *) fromDict:(NSDictionary *)dict
{
    OnCallNote *note = [[OnCallNote alloc] init];
    if ([dict valueForKey:kKeyAuthor]) {
        note.author = dict[kKeyAuthor];
    }
    if ([dict valueForKey:kKeyText]) {
        note.text = dict[kKeyText];
    }
    
    return note;
}

@end


@implementation OnCallShift

- (id) init
{
    self = [super init];
    if (self) {
        self.primaryMembers = [[NSMutableSet alloc] init];
        self.backupMembers = [[NSMutableSet alloc] init];
        self.users = [[NSMutableOrderedSet alloc] init];
        self.days = [[NSMutableArray alloc] init];
        self.overrides = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id) mutableCopy
{
    OnCallShift *ret = [[OnCallShift alloc] init];
    ret.name = self.name;
    ret.startDate = self.startDate;
    ret.endDate = self.endDate;
    ret.primaryMembers = [self.primaryMembers mutableCopy];
    ret.backupMembers = [self.backupMembers mutableCopy];
    ret.days = [self.days mutableCopy];
    ret.overrides = [self.overrides mutableCopy];
    return ret;
}

+ (OnCallShift *) fromDict:(NSDictionary *)dict
{
    OnCallShift *shift = [[OnCallShift alloc] init];
    shift.name = dict[@"name"];
    shift.startDate = [OnCallGroup stringToDateOnly:dict[@"start_date"]];
    shift.endDate = [OnCallGroup stringToDateOnly:dict[@"end_date"]];
    
    if ([dict[@"primary_members"] count] > 0) {
        for (NSString *qliqId in dict[@"primary_members"]) {
            [shift.primaryMembers addObject:qliqId];
        }
    }
    if ([dict[@"backup_members"] count] > 0) {
        for (NSString *qliqId in dict[@"backup_members"]) {
            [shift.backupMembers addObject:qliqId];
        }
    }
    
    if ([dict[@"schedules"] count] > 0) {
        for (NSDictionary *scheduleDict in dict[@"schedules"]) {
            OnCallDay *day = [OnCallDay fromDict:scheduleDict];
            if (day != nil) {
                [shift.days addObject:day];
            }
        }
    }
    
    if ([dict[@"overrides"] count] > 0) {
        for (NSDictionary *overrideDict in dict[@"overrides"]) {
            OnCallOverride *override = [OnCallOverride fromDict:overrideDict];
            if (override != nil) {
                [shift.overrides addObject:override];
            }
        }
    }
    
    return shift;
}

@end

@implementation OnCallDay

- (id) mutableCopy
{
    OnCallDay *copy = [[OnCallDay alloc] init];
    copy.isEnabled = self.isEnabled;
    copy.dayOfWeek = self.dayOfWeek;
    copy.endDayOfWeek = self.endDayOfWeek;
    copy.startTime = [NSDate dateWithTimeInterval:0 sinceDate:self.startTime];
    copy.endTime = [NSDate dateWithTimeInterval:0 sinceDate:self.endTime];
    copy.isOvernight = self.isOvernight;
    return copy;
}

+ (NSInteger) parseDayOfWeek:(NSString *)str
{
    if ([str isEqualToString:@"Mon"]) {
        return 2;
    } else if ([str isEqualToString:@"Tue"]) {
        return 3;
    } else if ([str isEqualToString:@"Wed"]) {
        return 4;
    } else if ([str isEqualToString:@"Thu"]) {
        return 5;
    } else if ([str isEqualToString:@"Fri"]) {
        return 6;
    } else if ([str isEqualToString:@"Sat"]) {
        return 7;
    } else if ([str isEqualToString:@"Sun"]) {
        return 1;
    } else {
        DDLogError(@"Cannot parse day's 'week_day': '%@'", str);
        return 0;
    }
}

+ (NSString *) dayOfWeekToString:(NSInteger)day
{
    switch (day) {
    case 1:
        return @"Sun";
    case 2:
        return @"Mon";
    case 3:
        return @"Tue";
    case 4:
        return @"Wed";
    case 5:
        return @"Thu";
    case 6:
        return @"Fri";
    case 7:
        return @"Sat";
    default:
        return @"";
    }
}

+ (NSInteger) incrementDayOfWeek:(NSInteger)day
{
    if (day == 7) {
        return 1;
    } else {
        return day + 1;
    }
}

+ (OnCallDay *) fromDict:(NSDictionary *)dict
{
    OnCallDay *day = [[OnCallDay alloc] init];
    day.isEnabled = [dict[@"enabled"] boolValue];
    day.dayOfWeek = [self parseDayOfWeek:dict[@"week_day"]];
    day.startTime = [OnCallGroup stringToTimeOnly:dict[@"start_time"]];
    day.endTime = [OnCallGroup stringToTimeOnly:dict[@"end_time"]];
    
    if ([day.startTime timeIntervalSince1970] >= [day.endTime timeIntervalSince1970]) {
        // End time is 1 day later
        day.endTime = [NSDate dateWithTimeInterval:SECONDS_PER_DAY sinceDate:day.endTime];
        day.endDayOfWeek = [OnCallDay incrementDayOfWeek:day.dayOfWeek];
        if (![OnCallGroup isMidnight:day.endTime]) {
            day.isOvernight = YES;
        }
    } else {
        day.endDayOfWeek = day.dayOfWeek;
        day.isOvernight = NO;
    }
    return day;
}

@end

@implementation OnCallOverride

- (id) init
{
    self = [super init];
    if (self) {
        self.primaryMembers = [[NSMutableSet alloc] init];
        self.backupMembers = [[NSMutableSet alloc] init];
    }
    return self;
}

- (OnCallDay *) toDay
{
    OnCallDay *day = [[OnCallDay alloc] init];
    day.isEnabled = self.isEnabled;
    day.startTime = [NSDate dateWithTimeInterval:0 sinceDate:self.startTime];
    day.endTime = [NSDate dateWithTimeInterval:0 sinceDate:self.endTime];
    day.dayOfWeek = 0;
    day.isOvernight = self.isOvernight;
    return day;
}

+ (OnCallOverride *) fromDict:(NSDictionary *)dict
{
    OnCallOverride *o = [[OnCallOverride alloc] init];
    o.isEnabled = [dict[@"enabled"] boolValue];
    o.date = [OnCallGroup stringToDateOnly:dict[@"date"]];
    o.startTime = [OnCallGroup stringToTimeOnly:dict[@"start_time"]];
    o.endTime = [OnCallGroup stringToTimeOnly:dict[@"end_time"]];
    o.notes = dict[@"notes"];
    
    if ([o.startTime timeIntervalSince1970] >= [o.endTime timeIntervalSince1970]) {
        // End time is 1 day later
        o.endTime = [NSDate dateWithTimeInterval:SECONDS_PER_DAY sinceDate:o.endTime];
        o.isOvernight = YES;
    } else {
        o.isOvernight = NO;
    }
    
    for (NSString *qliqId in dict[@"primary_members"]) {
        [o.primaryMembers addObject:qliqId];
    }
    for (NSString *qliqId in dict[@"backup_members"]) {
        [o.backupMembers addObject:qliqId];
    }
    
    return o;
}

@end

@implementation QliqUserWithOnCallHours

- (BOOL) isActiveOnDate:(NSDate *)date
{
    BOOL ret = NO;
    
    if (self.dayOfWeek == date.weekday) {
        NSDate *time = [NSDate date];
        NSComparisonResult result = [self.startTime compareTimeIgnoreDate:time isStartDate:YES];
        if (result == NSOrderedAscending || result == NSOrderedSame) {
            NSComparisonResult result = [self.endTime compareTimeIgnoreDate:time isStartDate:NO];
            if (self.isOvernight || (result == NSOrderedDescending || result == NSOrderedSame)) {
                ret = YES;
            }
        }
    } else if (self.isOvernight && self.endDayOfWeek == date.weekday) {
        NSDate *time = [NSDate date];
        NSComparisonResult result = [self.endTime compareTimeIgnoreDate:time isStartDate:NO];
        if (result == NSOrderedDescending || result == NSOrderedSame) {
            ret = YES;
        }
    }
    
    return ret;
}

- (BOOL) isFullDay
{
    return [self.startTime compareTimeIgnoreDate:self.endTime isStartDate:nil] == NSOrderedSame;
}

@end

