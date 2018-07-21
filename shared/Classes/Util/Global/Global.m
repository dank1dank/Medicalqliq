//
//  Global.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 9/14/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Global.h"
#import "Helper.h"

static const int numberOfDaysOnDatePicker = 30;
static const int numberOfFutureDaysOnDatePicker = 7;

static Global *sharedInstance = nil;

@implementation Global

@synthesize numDays,numFutureDays;

#pragma mark -

#pragma mark Singleton Methods

+ (Global *)sharedInstance {
	if(sharedInstance == nil){
		sharedInstance = [[super allocWithZone:NULL] init];
	}
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
	return [[self sharedInstance] retain];
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (unsigned)retainCount {
	return NSUIntegerMax;
}

- (oneway void)release 
{
	//do nothing
}

- (id)autorelease {
	return self;
}

- (id)init {
	self=[super init];
	self.numDays = numberOfDaysOnDatePicker;
	self.numFutureDays = numberOfFutureDaysOnDatePicker;
	
	dateArrayForCensus = [[NSMutableArray alloc] init];
	dateArrayForAppts = [[NSMutableArray alloc] init];
	
	return self;
}

- (NSMutableArray *) dateArrayForCensus
{
	[dateArrayForCensus removeAllObjects];
	[dateArrayForCensus addObject:NSLocalizedString(@"Pending", @"Pending")];
	[dateArrayForCensus addObjectsFromArray:[Helper getDates:self.numDays]];
	return dateArrayForCensus;
}

- (NSMutableArray *) dateArrayForAppts
{
	[dateArrayForAppts removeAllObjects];
	[dateArrayForAppts addObjectsFromArray:[Helper getFutureDates:self.numFutureDays]];
	[dateArrayForAppts addObjectsFromArray:[Helper getDates:self.numDays]];
	return dateArrayForAppts;
}

- (void)dealloc {
	[super dealloc];
	// Should never be called, but just here for clarity really.
	[dateArrayForCensus release];
	[self.dateArrayForAppts release];
	
}

@end