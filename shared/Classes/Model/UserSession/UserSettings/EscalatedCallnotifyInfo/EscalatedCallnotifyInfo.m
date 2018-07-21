//
//  EscalatedCallnotifyInfo.m
//  qliq
//
//  Created by Valeriy Lider on 7/14/14.
//
//

#import "EscalatedCallnotifyInfo.h"

NSString * EscalatedCall = @"Escalated Call";

@implementation EscalatedCallnotifyInfo

//Init with default settings
- (id)init{
    self = [super init];
    if (self) {
        [self loadDefaults];
    }
    return self;
}

- (void) loadDefaults{
    
    self.calleridNumber = @(0);
    self.calleridName = @"";
    self.escalationNumber = @"";
    self.escalateWeekends = NO;
    self.escalateWeeknights = NO;
    self.escalateWeekdays = NO;
}


- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self) {

        self.calleridNumber = [aDecoder decodeObjectForKey:@"calleridNumber"];
        self.calleridName = [aDecoder decodeObjectForKey:@"calleridName"];
        self.escalationNumber = [aDecoder decodeObjectForKey:@"escalationNumber"];
        self.escalateWeekends = [[aDecoder decodeObjectForKey:@"escalateWeekends"] boolValue];
        self.escalateWeeknights = [[aDecoder decodeObjectForKey:@"escalateWeeknights"] boolValue];
        self.escalateWeekdays = [[aDecoder decodeObjectForKey:@"escalateWeekdays"] boolValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.calleridNumber forKey:@"calleridNumber"];
    [aCoder encodeObject:self.calleridName forKey:@"calleridName"];
    [aCoder encodeObject:self.escalationNumber forKey:@"escalationNumber"];
    [aCoder encodeObject:@(self.escalateWeekends) forKey:@"escalateWeekends"];
    [aCoder encodeObject:@(self.escalateWeeknights) forKey:@"escalateWeeknights"];
    [aCoder encodeObject:@(self.escalateWeekdays) forKey:@"escalateWeekdays"];
}

@end
