//
//  ADDelegateList.h
//
//  Created by Ivan on 24.02.11.
//  Copyright 2011 Al Digit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADDelegateList : NSObject
{
	NSMutableArray *mDelegates;
}

- (void)addDelegate:(id)delegate;
- (void)removeDelegate:(id)delegate;

- (void)performSelectorOnObjects:(SEL)selector;
- (void)performSelectorOnObjects:(SEL)selector withObject:(id)object;
- (void)performSelectorOnObjects:(SEL)selector withObject:(id)object1 withObject:(id)object2;

- (NSInteger)count;

@end
