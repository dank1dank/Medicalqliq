//
//  ADDelegateList.m
//
//  Created by Ivan on 24.02.11.
//  Copyright 2011 Al Digit. All rights reserved.
//

#import "ADDelegateList.h"

@implementation ADDelegateList

- (id)init {
	if ((self = [super init])) {
		mDelegates = [NSMutableArray new];
	}
	
	return self;
}

- (void)dealloc
{
	[mDelegates release];

	[super dealloc];
}

#pragma mark * Public

- (void)addDelegate:(id)delegate
{
	NSValue *value = [NSValue valueWithPointer:delegate];
	[mDelegates addObject:value];
}

- (void)removeDelegate:(id)delegate
{
	for (NSValue *value in mDelegates)
	{
		if ([value pointerValue] == delegate) {
			[mDelegates removeObject:value];
			return;
		}
	}
}

- (void)performSelectorOnObjects:(SEL)selector
{
	NSArray *delegatesCopy = [mDelegates copy];
	for (id value in delegatesCopy)
	{
		id object = [value pointerValue];
        
		if ([object respondsToSelector:selector]) {
			[object performSelector:selector];
		}
	}
    
	[delegatesCopy release];
}

- (void)performSelectorOnObjects:(SEL)selector withObject:(id)arg
{
	NSArray *delegatesCopy = [mDelegates copy];
	for (id value in delegatesCopy)
	{
		id object = [value pointerValue];

        if ([object respondsToSelector:selector]) {
			[object performSelector:selector withObject:arg];
		}
	}
    
	[delegatesCopy release];
}

- (void)performSelectorOnObjects:(SEL)selector withObject:(id)arg1 withObject:(id)arg2
{
	NSArray *delegatesCopy = [mDelegates copy];
	for (id value in delegatesCopy)
	{
		id object = [value pointerValue];
        
		if ([object respondsToSelector:selector]) {
			[object performSelector:selector withObject:arg1 withObject:arg2];
		}
	}
    
	[delegatesCopy release];
}

- (NSInteger) count
{
	return [mDelegates count];
}

#pragma mark - Private

- (NSString *)description
{
    NSMutableString *string = [NSMutableString stringWithFormat:@"(\n"];
    
    for (NSValue *delegate in mDelegates)
    {
        id object = [delegate pointerValue];
        [string appendFormat:@"\t%@\n", object];
    }
    
    [string appendFormat:@")\n"];
    
    return string;
}

@end
