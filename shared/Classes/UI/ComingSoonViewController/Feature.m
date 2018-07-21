//
//  Feature.m
//  qliq
//
//  Created by Paul Bar on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Feature.h"
#import "UserSessionService.h"
#import "UserSession.h"
//#import "User.h"

@implementation Feature

@synthesize name;
@synthesize description;

static NSString *configFileName = @"comingSoonFeatures";
static NSString *requested_features_key_prefix = @"requestedFeatures-";

+(Feature*)getFromPlistFeatureNamed:(NSString *)featureName
{
    NSString *configFilePath = [[NSBundle mainBundle] pathForResource:configFileName ofType:@"plist"];
    NSDictionary *configFileContent = [NSDictionary dictionaryWithContentsOfFile:configFilePath];
    NSDictionary *featureDict = [configFileContent objectForKey:featureName];
    return [self featureWithDict:featureDict];
}

+(Feature*)featureWithDict:(NSDictionary *)dict
{
    NSString *name = [dict objectForKey:@"name"];
    NSString *description = [dict objectForKey:@"description"];
    Feature *feature = [[Feature alloc] initWithName:name andDescription:description];
    return [feature autorelease];
}

-(id) initWithName:(NSString *)_name andDescription:(NSString *)_description
{
    self = [super init];
    if(self)
    {
        name = [_name retain];
        description = [_description retain];
    }
    return self;
}

-(void) dealloc
{
    [name release];
    [description release];
    [super dealloc];
}

-(void) saveAsRequested
{
    if([self.name length] == 0)
    {
        return;
    }
    NSString *qliqId = [UserSessionService currentUserSession].user.qliqId;
    NSString *defaultsKey = [NSString stringWithFormat:@"%@%@", requested_features_key_prefix, qliqId];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:[defaults objectForKey:defaultsKey]];
    if(array == nil)
    {
        array = [[[NSMutableArray alloc] init] autorelease];
    }
    if(![array containsObject:self.name])
    {
        [array addObject:self.name];
    }
    [defaults setObject:array forKey:defaultsKey];
    [defaults synchronize];
}

-(BOOL) isRequested
{
    if([self.name length] == 0)
    {
        return NO;
    }
    
    NSString *qliqId = [UserSessionService currentUserSession].user.qliqId;
    NSString *defaultsKey = [NSString stringWithFormat:@"%@%@", requested_features_key_prefix, qliqId];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *array = [defaults objectForKey:defaultsKey];
    
    return [array containsObject:self.name];
}

@end
