//
//  QliqLogFormatter.h
//  qliq
//
//  Created by Aleksey Garbarev on 10/9/12.
//
//

#import <Foundation/Foundation.h>
#import "Log.h"

@interface QliqLogFormatter : NSObject <DDLogFormatter>
@property (nonatomic) BOOL showClassName;   /*Default YES*/
@property (nonatomic) BOOL insertNewLine;   /*Default YES*/
@property (nonatomic) BOOL showThreadID;    /*Default YES*/
@property (nonatomic) BOOL isAslFormatter;  /*Default NO*/

@end
