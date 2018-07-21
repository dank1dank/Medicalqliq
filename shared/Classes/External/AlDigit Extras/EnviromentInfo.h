//
//  EnviromentInfo.h
//  qliq
//
//  Created by Aleksey Garbarev on 06.08.13.
//
//

#import <Foundation/Foundation.h>

@interface EnviromentInfo : NSObject

+ (id) sharedInfo;

@property (nonatomic, readonly) BOOL hasSourceControlInfo;
@property (nonatomic, readonly) NSString *branch;
@property (nonatomic, readonly) NSString *commitNumber;
@property (nonatomic, readonly) NSString *commitHash;
@property (nonatomic, readonly) NSString *commitHashShort;


@property (nonatomic, readonly) NSString *clangVersion;
@property (nonatomic, readonly) NSString *llvmVersion;
@property (nonatomic, readonly) NSString *xcodeVersion;


@end
