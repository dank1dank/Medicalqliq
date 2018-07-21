//
//  UserFeatureInfo.m
//  qliq
//
//  Created by Valerii Lider on 4/28/16.
//
//

#import "UserFeatureInfo.h"

#define kEMRIntegration                    @"emr_integration"
#define kFAXIntegration                    @"fax_integration"
#define kOnCallGroups                      @"oncall_groups"
#define kKiteworksIntegrtation             @"kiteworks_integration"
#define kCareChannelsIntegrtation          @"care_channels"
#define kFillAndSignAvailable              @"fill_and_sign"

@implementation UserFeatureInfo

#pragma mark - Lifecycle

- (void) loadDefaults{
    
    self.isEMRIntegated = NO;
    self.isFAXIntegated = NO;
    self.isOnCallGroupsAllowed = NO;
    self.isKiteworksIntegrated = NO;
    self.isCareChannelsIntegrated = NO;
    self.isFillAndSignAvailable = NO;
}

//Init with default settings
- (instancetype)init{
    
    self = [super init];
    if (self) {
        [self loadDefaults];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    if(self) {
        self.isEMRIntegated        = [aDecoder containsValueForKey:kEMRIntegration] ? [aDecoder decodeBoolForKey:kEMRIntegration] : NO;
        self.isFAXIntegated        = [aDecoder containsValueForKey:kFAXIntegration] ? [aDecoder decodeBoolForKey:kFAXIntegration] : NO;
        self.isOnCallGroupsAllowed = [aDecoder containsValueForKey:kOnCallGroups] ? [aDecoder decodeBoolForKey:kOnCallGroups] : NO;
        self.isKiteworksIntegrated = [aDecoder containsValueForKey:kKiteworksIntegrtation] ? [aDecoder decodeBoolForKey:kKiteworksIntegrtation] : NO;
        self.isCareChannelsIntegrated = [aDecoder containsValueForKey:kCareChannelsIntegrtation] ? [aDecoder decodeBoolForKey:kCareChannelsIntegrtation] : NO;
        self.isFillAndSignAvailable = [aDecoder containsValueForKey:kFillAndSignAvailable] ? [aDecoder decodeBoolForKey:kFillAndSignAvailable] : NO;
    }
   
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.isEMRIntegated        forKey:kEMRIntegration];
    [aCoder encodeBool:self.isFAXIntegated        forKey:kFAXIntegration];
    [aCoder encodeBool:self.isOnCallGroupsAllowed forKey:kOnCallGroups];
    [aCoder encodeBool:self.isKiteworksIntegrated forKey:kKiteworksIntegrtation];
    [aCoder encodeBool:self.isCareChannelsIntegrated forKey:kCareChannelsIntegrtation];
    [aCoder encodeBool:self.isFillAndSignAvailable forKey:kFillAndSignAvailable];
}

@end
