//
//  QliqStorDBService.h
//  qliq
//
//  Created by Adam Sowa on 1/29/14.
//
//

#import <Foundation/Foundation.h>

enum SubjectOperation {
    PushOperation = 1,
    PullOperation = 2
};

// The methods of this class are not actually used right now because they are for
// qliqStor queries which we no longer used in the app
@interface QliqStorDBService : NSObject

+ (void) setLastSubjectDatabaseUuid:(NSString *)databaseUuid forSubject:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation;
+ (NSString *) lastSubjectDatabaseUuid:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation;
+ (int) lastSubjectSeq:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation;
+ (void) setLastSubjectSeq:(int)seq forSubject:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation;
+ (void) setLastSubjectSeqIfGreater:(int)seq forSubject:(NSString *)subject forUser:(NSString *)qliqId andOperation:(int)operation;

@end
