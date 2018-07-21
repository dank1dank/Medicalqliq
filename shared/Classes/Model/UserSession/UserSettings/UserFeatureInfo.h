//
//  UserFeatureInfo.h
//  qliq
//
//  Created by Valerii Lider on 4/28/16.
//
//

#import <Foundation/Foundation.h>

@interface UserFeatureInfo : NSObject <NSCoding>

@property (nonatomic, assign) BOOL isEMRIntegated;
@property (nonatomic, assign) BOOL isFAXIntegated;
@property (nonatomic, assign) BOOL isOnCallGroupsAllowed;
@property (nonatomic, assign) BOOL isKiteworksIntegrated;
@property (nonatomic, assign) BOOL isCareChannelsIntegrated;
@property (nonatomic, assign) BOOL isFillAndSignAvailable;

@end
