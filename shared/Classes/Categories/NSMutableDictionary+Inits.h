//
//  NSDictionary+Inits.h
//  CCiPhoneApp
//
//  Created by Adam Sowa on 8/11/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableDictionary (Inits)

- (id)initWithObjectsAndKeysSkipNilValues:(id)firstValue,...;
- (id)initWithKeysAndObjects:(id)firstKey ,...;

+ (id)dictionaryWithObjectsAndKeysSkipNilValues:(id)firstValue,...;
@end
