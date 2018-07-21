//
//  QxQliqStorClient.h
//  qliq
//
//  Created by Adam Sowa on 02/06/17.
//
//

#import <Foundation/Foundation.h>

// Object representing qliqStor and its group
@interface QliqStorPerGroup : NSObject

- (NSString *) qliqStorQliqId;
- (NSString *) groupQliqId;
- (NSString *) groupName;

- (BOOL) isEmpty;
// Use this method for string to show in UI
- (NSString *) displayName;

@end

@interface QxQliqStorClient : NSObject

// Returns nil if no default qS
+ (QliqStorPerGroup *) defaultQliqStor;
+ (void) setDefaultQliqStor:(NSString *)qliqStorQliqId groupQliqId:(NSString *)groupQliqId;

+ (BOOL) shouldShowQliqStorSelectionDialog;

// Returns array of QliqStorPerGroup objects
+ (NSArray *) qliqStors;

@end
