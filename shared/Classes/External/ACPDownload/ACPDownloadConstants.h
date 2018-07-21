//
//  ACPDownloadConstants.h
//  ACPDownload
//
//  Created by Palmero, Antonio on 1/16/15.
//  Copyright (c) 2015 Antonio Casero Palmero. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACPDownloadConstants : NSObject

extern NSString *const kACPStrokeAnimationKey;
extern NSString *const kACPRotationAnimationKey;

typedef NS_ENUM(NSUInteger, ACPDownloadStatus) {
    ACPDownloadStatusNone,
    ACPDownloadStatusRunning,
    ACPDownloadStatusIndeterminate,
    ACPDownloadStatusCompleted,

};

@end
// Copyright belongs to original author
// http://code4app.net (en) http://code4app.com (cn)
// From the most professional code share website: Code4App.net