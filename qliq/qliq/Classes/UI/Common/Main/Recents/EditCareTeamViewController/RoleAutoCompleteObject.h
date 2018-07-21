//
//  RoleAutoCompleteObject.h
//  qliq
//
//  Created by Valerii Lider on 7/22/16.
//
//

#import <Foundation/Foundation.h>
#import "MLPAutoCompletionObject.h"

@interface RoleAutoCompleteObject : NSObject <MLPAutoCompletionObject>

- (id)initWithRoleString:(NSString *)name;

@end
