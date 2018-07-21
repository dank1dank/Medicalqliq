//
//  EscalatedCallnotifyInfo.h
//  qliq
//
//  Created by Valeriy Lider on 7/14/14.
//
//

#import <Foundation/Foundation.h>

extern NSString * EscalatedCall;

@interface EscalatedCallnotifyInfo : NSObject

@property (nonatomic, strong) NSNumber *calleridNumber;
@property (nonatomic, strong) NSString *calleridName;
@property (nonatomic, strong) NSString *escalationNumber;
@property (nonatomic, assign) BOOL escalateWeekends;
@property (nonatomic, assign) BOOL escalateWeeknights;
@property (nonatomic, assign) BOOL escalateWeekdays;

@end
