//
//  RoleTextFieldDataSourceObject.m
//  qliq
//
//  Created by Valerii Lider on 7/22/16.
//
//

#import "RoleTextFieldDataSourceObject.h"
#import "RoleAutoCompleteObject.h"

@interface RoleTextFieldDataSourceObject ()

@property (strong, nonatomic) NSArray *rolesObjects;

@end

static RoleTextFieldDataSourceObject *sharedManager;

@implementation RoleTextFieldDataSourceObject

#pragma mark - MLPAutoCompleteTextField DataSource

+ (RoleTextFieldDataSourceObject *)shared {
    
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        sharedManager = [[RoleTextFieldDataSourceObject alloc] init];
    });
    return sharedManager;
}

//example of asynchronous fetch:
- (void)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
 possibleCompletionsForString:(NSString *)string
            completionHandler:(void (^)(NSArray *))handler
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        if(self.simulateLatency){
            CGFloat seconds = arc4random_uniform(4)+arc4random_uniform(4); //normal distribution
            NSLog(@"sleeping fetch of completions for %f", seconds);
            sleep(seconds);
        }
        
        NSArray *completions;
        if(self.testWithAutoCompleteObjectsInsteadOfStrings){
            completions = [self allRolesObjects];
        } else {
            completions = [self allRoles];
        }
        
        handler(completions);
    });
}


 - (NSArray *)autoCompleteTextField:(MLPAutoCompleteTextField *)textField
 possibleCompletionsForString:(NSString *)string
{
    
    if(self.simulateLatency){
        CGFloat seconds = arc4random_uniform(4)+arc4random_uniform(4); // normal distribution
        NSLog(@"sleeping fetch of completions for %f", seconds);
        sleep(seconds);
    }
    
    NSArray *completions;
    if(self.testWithAutoCompleteObjectsInsteadOfStrings){
        completions = [self allRolesObjects];
    } else {
        completions = [self allRoles];
    }
    
    return completions;
}


- (NSArray *)allRolesObjects
{
    if(!self.rolesObjects){
        NSArray *roleStrings = [self allRoles];
        NSMutableArray *mutableRoles = [NSMutableArray new];
        for(NSString *role in roleStrings){
            RoleAutoCompleteObject *autoCompleteObject = [[RoleAutoCompleteObject alloc] initWithRoleString:role];
            [mutableRoles addObject:autoCompleteObject];
        }
        
        [self setRolesObjects:[NSArray arrayWithArray:mutableRoles]];
    }
    
    return self.rolesObjects;
}


- (NSArray *)allRoles
{
    NSArray *roleStrings =
    @[
      @"Admitting Physician",
      @"Attending Physician",
      @"Consulting Physician",
      @"Reffering Physician",
      @"Care Coordinator"
      ];
    return roleStrings;
}


@end
