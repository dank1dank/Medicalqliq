//
//  CryptoWrapper.h
//  qliq
//
//  Created by Paul Bar on 5/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CryptoWrapper : NSObject

-(NSString*) encryptFileAtPath:(NSString *)filePath andSaveToPath:(NSString*)outputFilePath outChecksum:(NSString **)outChecksum; //returns generated key if succsess. nil otherwise
-(BOOL) decryptFileAthPath:(NSString *)filePath withKey:(NSString *)key andSaveToPath:(NSString*)outputFile;

@end
