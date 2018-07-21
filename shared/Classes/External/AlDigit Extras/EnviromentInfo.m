//
//  EnviromentInfo.m
//  qliq
//
//  Created by Aleksey Garbarev on 06.08.13.
//
//

#import "EnviromentInfo.h"

@implementation EnviromentInfo {
    NSDictionary *sourceControlDict;
    NSDictionary *buildEnviromentDict;
}

static EnviromentInfo *SEnviromentInfo = nil;

+ (id) sharedInfo
{
    @synchronized(self) {
        if (!SEnviromentInfo) {
            
            SEnviromentInfo = [[EnviromentInfo alloc] init];
        }
    }
    return SEnviromentInfo;
}

- (id)init
{
    self = [super init];
    if (self) {
        NSString *envDictPath = [[NSBundle mainBundle] pathForResource:@"Enviroment" ofType:@"plist"];
        NSDictionary *envDict = [NSDictionary dictionaryWithContentsOfFile:envDictPath];
        buildEnviromentDict = envDict[@"BuildEnviroment"];
        NSObject *sourceControl = envDict[@"SourceControl"];
        if ([sourceControl isKindOfClass:[NSDictionary class]]) {
            sourceControlDict = envDict[@"SourceControl"];
        }

    }
    return self;
}

- (BOOL)hasSourceControlInfo
{
    return sourceControlDict != nil;
}

- (NSString *)branch
{
    return sourceControlDict[@"branch"];
}

- (NSString *)commitNumber
{
    return sourceControlDict[@"commit_number"];
}

- (NSString *)commitHash
{
    return sourceControlDict[@"hash"];
}

- (NSString *)commitHashShort
{
    return sourceControlDict[@"hash_short"];
}

- (NSString *)clangVersion
{
    return buildEnviromentDict[@"clang"];
}

- (NSString *)llvmVersion
{
    return buildEnviromentDict[@"llvm"];
}


- (NSString *)xcodeVersion
{
    return buildEnviromentDict[@"xcode"];
}




@end
