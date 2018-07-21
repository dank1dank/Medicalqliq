//
//  Multiparty.h
//  qliq
//
//  Created by Adam Sowa on 28/06/16.
//
//

#import <Foundation/Foundation.h>

@interface Multiparty : NSObject
- (NSString *) qliqId;
- (NSArray *) participantQliqIds;
- (BOOL) containsParticipant:(NSString *)qliqId;
- (NSString *) roleForQliqId:(NSString *)qliqId;
+ (Multiparty *) parseJson:(NSString *)json;
@end


@interface MultipartyDao : NSObject
+ (BOOL) existsWithQliqId:(NSString *)qliqId;
+ (Multiparty *) selectOneWithQliqId:(NSString *)qliqId;
+ (BOOL) insertOrUpdate:(Multiparty *)mp;
@end
