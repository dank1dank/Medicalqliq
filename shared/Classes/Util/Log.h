/*
 *  Log.h
 *  CCiPhoneApp
 *
 *  Created by Adam Sowa on 9/14/11.
 *  Copyright 2011 Ardensys Inc. All rights reserved.
 *
 */

#import "CocoaLumberjack.h"

#undef LOG_FLAG_ERROR
#undef LOG_FLAG_WARN
#undef LOG_FLAG_INFO
#undef LOG_FLAG_DEBUG
#undef LOG_FLAG_VERBOSE

#undef LOG_LEVEL_ERROR
#undef LOG_LEVEL_WARN
#undef LOG_LEVEL_INFO
#undef LOG_LEVEL_DEBUG
#undef LOG_LEVEL_VERBOSE

#undef DDLogError
#undef DDLogWarn
#undef DDLogInfo
#undef DDLogDebug
#undef DDLogVerbose

#define LOG_FLAG_ERROR      (1 << 0)  // 0...00001
#define LOG_FLAG_WARN       (1 << 1)  // 0...00010
#define LOG_FLAG_SUPPORT    (1 << 2)  // 0...00100
#define LOG_FLAG_INFO       (1 << 3)  // 0...01000
#define LOG_FLAG_DEBUG      (1 << 4)  // 0...10000
#define LOG_FLAG_VERBOSE    (1 << 5)  // 0..100000

#define LOG_LEVEL_ERROR     (LOG_FLAG_ERROR)                        // 0...00001
#define LOG_LEVEL_WARN      (LOG_LEVEL_ERROR  | LOG_FLAG_WARN)      // 0...00011
#define LOG_LEVEL_SUPPORT   (LOG_LEVEL_WARN   | LOG_FLAG_SUPPORT)   // 0...00111
#define LOG_LEVEL_INFO      (LOG_FLAG_SUPPORT | LOG_FLAG_INFO)      // 0...01111
#define LOG_LEVEL_DEBUG     (LOG_LEVEL_INFO   | LOG_FLAG_DEBUG)     // 0...11111
#define LOG_LEVEL_VERBOSE   (LOG_LEVEL_DEBUG  | LOG_FLAG_VERBOSE)   // 0..111111

#define DDLogError(frmt, ...)   LOG_MAYBE(NO,                LOG_LEVEL_DEF, LOG_FLAG_ERROR,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogWarn(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, LOG_FLAG_WARN,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogSupport(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, LOG_FLAG_SUPPORT, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogInfo(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, LOG_FLAG_INFO,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogDebug(frmt, ...)   LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, LOG_FLAG_DEBUG,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogVerbose(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, LOG_FLAG_VERBOSE, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

extern DDLogLevel ddLogLevel;
