//
//  DeviceInfo.h
//  Eyeris
//
//  Created by Ivan Zezyulya on 24.01.12.
//  Copyright (c) 2012 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <mach/machine.h>

@interface DeviceInfo : NSObject

+ (DeviceInfo *) sharedInfo;

@property (nonatomic, strong, readonly) NSString *platform;
@property (nonatomic, strong, readonly) NSString *iosVersion;
@property (nonatomic, assign, readonly) int numberOfPhisicalCores;
@property (nonatomic, assign, readonly) int numberOfLogicalCores;
@property (nonatomic, assign, readonly) cpu_type_t CPUType;

@property (nonatomic, assign, readonly) BOOL isMuted;
@property (nonatomic, assign, readonly) Float32 outputVolume;

@property (nonatomic, readonly) BOOL isIPhone;
@property (nonatomic, readonly) BOOL isIPad;
@property (nonatomic, readonly) BOOL isIPod;
@property (nonatomic, readonly) BOOL isSimulator;

@property (nonatomic, readonly) int generationMajor;
@property (nonatomic, readonly) int generationMinor;

@property (nonatomic, readonly) int iosVersionMajor;
@property (nonatomic, readonly) int iosVersionMinor;
@property (nonatomic, readonly) int iosVersionRevision;

@property (nonatomic, readonly) float keyboardHeightPortrait;

@property (nonatomic, readonly) int screenWidthPixels;
@property (nonatomic, readonly) int screenHeightPixels;

@end
