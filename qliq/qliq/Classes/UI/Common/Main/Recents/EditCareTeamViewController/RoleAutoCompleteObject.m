//
//  RoleAutoCompleteObject.m
//  qliq
//
//  Created by Valerii Lider on 7/22/16.
//
//

#import "RoleAutoCompleteObject.h"

@interface RoleAutoCompleteObject ()
@property (strong) NSString *roleString;
@end

@implementation RoleAutoCompleteObject
- (id)initWithRoleString:(NSString *)name
{
    self = [super init];
    if (self) {
        [self setRoleString:name];
    }
    return self;
}

#pragma mark - MLPAutoCompletionObject Protocl

- (NSString *)autocompleteString
{
    return self.roleString;
}

@end
