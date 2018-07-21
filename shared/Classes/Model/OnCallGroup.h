//
//  OnCallGroup.h
//  qliq
//
//  Created by Adam on 10/08/15.
//
//

#import <Foundation/Foundation.h>
#import "QliqGroup.h"

#define kOnCallGroupsChangedNotification @"OnCallGroupsChangedNotification"
// keys for the above notification
#define kKeyOnCallDeletedIds @"deletedOnCallGroupQliqId"
#define kKeyOnCallNewGroups @"addedOnCallGroup"
#define kKeyOnCallChangedGroups @"changedOnCallGroup"

@interface QliqUserWithOnCallHours : NSObject

@property (nonatomic, readwrite) NSInteger dayOfWeek;
@property (nonatomic, readwrite) NSInteger endDayOfWeek;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, readwrite) BOOL isOvernight;
@property (nonatomic, readwrite) BOOL isBackup;
@property (nonatomic, strong) QliqUser *user;

- (BOOL) isActiveOnDate:(NSDate *)date;
- (BOOL) isFullDay;

@end


@interface OnCallDay : NSObject

@property (nonatomic, readwrite) BOOL isEnabled;
@property (nonatomic, readwrite) NSInteger dayOfWeek;
@property (nonatomic, readwrite) NSInteger endDayOfWeek;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, readwrite) BOOL isOvernight;

- (id) mutableCopy;

+ (OnCallDay *) fromDict:(NSDictionary *)dict;
+ (NSString *) dayOfWeekToString:(NSInteger)day;
+ (NSInteger) incrementDayOfWeek:(NSInteger)day;

@end

@interface OnCallOverride : NSObject

@property (nonatomic, readwrite) BOOL isEnabled;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, readwrite) BOOL isOvernight;
@property (nonatomic, strong) NSMutableSet *primaryMembers;
@property (nonatomic, strong) NSMutableSet *backupMembers;
@property (nonatomic, strong) NSString *notes;

- (id) init;
- (OnCallDay *) toDay;
+ (OnCallOverride *) fromDict:(NSDictionary *)dict;

@end

@interface OnCallShift : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, strong) NSMutableSet *primaryMembers;
@property (nonatomic, strong) NSMutableSet *backupMembers;
@property (nonatomic, strong) NSMutableOrderedSet *users;
@property (nonatomic, strong) NSMutableArray *days;
@property (nonatomic, strong) NSMutableArray *overrides;
@property (nonatomic, strong) OnCallDay *currentDay;
@property (nonatomic, strong) OnCallOverride *currentOverride;

- (id) init;
- (id) mutableCopy;
+ (OnCallShift *) fromDict:(NSDictionary *)dict;

@end

#define kKeyMemberQliqId @"qliq_id"
#define kKeyNotes @"notes"

@interface OnCallMemberNotes : NSObject

@property (nonatomic, strong) NSString *memberQliqId;
@property (nonatomic, strong) NSMutableArray *notes;

- (id) init;
+ (OnCallMemberNotes *) fromDict:(NSDictionary *)dict;

@end

#define kKeyAuthor @"author"
#define kKeyText @"note"

@interface OnCallNote : NSObject

@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *text;

- (id) init;
+ (OnCallNote *) fromDict:(NSDictionary *)dict;

@end

@interface OnCallGroup : QliqGroup

@property (nonatomic, strong) NSMutableArray *shifts;
@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, strong) NSMutableArray *notesPerMember;
@property (nonatomic, readwrite) NSUInteger lastUpdated;
@property (nonatomic, strong) NSDictionary *shifts_json;

- (id) initWithQliqGroup:(QliqGroup *)group;
- (NSArray *) shiftsForDate:(NSDate *) nowDate withCalendar:(NSCalendar *)calendar;
- (OnCallShift *) shiftForDate:(NSDate *) nowDate withCalendar:(NSCalendar *)calendar;
- (NSArray *) membersWithHoursForDate:(NSDate *) nowDate withCalendar:(NSCalendar *)calendar;
- (NSArray *) notesForDate:(NSDate *) nowDate;
- (NSArray *)getOnlyContacts;
- (OnCallMemberNotes *)getNotesForUser:(QliqUser *)user;

+ (OnCallGroup *) fromDict:(NSDictionary *)dict;
+ (NSArray *) fromJsonArray:(NSArray *)json;
+ (void) setOnCallGroups:(NSArray *)groups;
+ (NSArray *) onCallGroups;
+ (NSArray *) activeOnCallGroups;
+ (NSArray *) onCallGroupsActiveForDate:(NSDate *)date withCalendar:(NSCalendar *)calendar;
+ (NSUInteger) lastUpdated:(NSString *)qliqId;
- (void) loadOnCallShiftsFromJson;

+ (BOOL) hasConfigInDatabase;
+ (NSString *) loadFromDatabase;
+ (BOOL) saveToDatabaseJson:(NSString *)json;

// Modifications from JSON arguments
+ (BOOL) processAllGroupsJson:(NSArray *)groups;
+ (void) processSingleGroupJson:(NSDictionary *)newGroup;
+ (BOOL) processBulkJsonUpdate:(NSArray *)array;
+ (void) deleteOnCallGroupWithQliqId:(NSString *)qliqId;

+ (BOOL) date:(NSDate *)date isBetweenDate:(NSDate *)beginDate andDate:(NSDate *)endDate;
+ (NSDate *) setDateComponentsTo1970:(NSDate *)date;

@end
