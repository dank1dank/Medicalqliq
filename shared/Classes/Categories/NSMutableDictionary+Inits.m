//
//  NSDictionary+Inits.m
//  CCiPhoneApp
//
//  Created by  user on 8/11/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
// Created by Adam Sowa on 8/11/2011

#import "NSMutableDictionary+Inits.h"

//
// http://macdevelopertips.com/objective-c/objective-c-categories.html
//
@implementation NSMutableDictionary (Inits)

- (id)initWithObjectsAndKeysSkipNilValues:(id)firstValue,...
{
	self = [self init];
	
	va_list args;
	va_start(args, firstValue);
	
	id object = firstValue;
	id key = va_arg(args, id);
	
	while (key != nil) {
		if (object != nil) {
			[self setObject:object forKey:key];
		}
		
		object = va_arg(args, id);
		key = va_arg(args, id);
	}	
	va_end(args);
	return self;	
}

- (id)initWithKeysAndObjects:(id)firstKey ,...
{
	self = [self init];
	
	va_list args;
	va_start(args, firstKey);
	
	id key = firstKey;
	
	while (key != nil) {
		id object = va_arg(args, id);
		if (object != nil)
			[self setObject:object forKey:key];
		key = va_arg(args, id);
	}	
	va_end(args);
	return self;
}

+ (id)dictionaryWithObjectsAndKeysSkipNilValues:(id)firstValue,...
{
	id newInstance = [[[self class] alloc] init];

	va_list args;
	va_start(args, firstValue);
	
	id object = firstValue;
	id key = va_arg(args, id);
	
	while (key != nil) {
		if (object != nil) {
			[newInstance setObject:object forKey:key];
		}
		
		object = va_arg(args, id);
		key = va_arg(args, id);
	}	
	va_end(args);	
	
	return [newInstance autorelease];
}

@end
