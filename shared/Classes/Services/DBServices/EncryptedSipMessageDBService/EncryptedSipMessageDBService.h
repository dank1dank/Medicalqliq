//
//  EncryptedSipMessageDBService.h
//  qliq
//
//  Created by Adam on 12/3/12.
//
//

#import <Foundation/Foundation.h>
#import "EncryptedSipMessage.h"

@interface EncryptedSipMessageDBService : NSObject

@property (nonatomic, strong) FMDatabase *database;

- (id) initWithDatabase:(FMDatabase *) _database;
- (BOOL) insert: (EncryptedSipMessage *)msg;
- (NSArray *) messagesWithToQliqId: (NSString *)toQliqId limit:(int)limit;
- (BOOL) delete_: (int)messageId;
- (BOOL) deleteOlderThen:(NSTimeInterval)timestamp;

+ (EncryptedSipMessageDBService *) sharedService;

@end
