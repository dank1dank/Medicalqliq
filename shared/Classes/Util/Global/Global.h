//
//  Global.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 9/14/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

@interface Global : NSObject {
	NSMutableArray *dateArrayForCensus;
	NSMutableArray *dateArrayForAppts;
	NSInteger numDays;
	NSInteger numFutureDays;
	
	
}

@property (nonatomic, readwrite) NSInteger numDays;
@property (nonatomic, readwrite) NSInteger numFutureDays;


+ (Global *)sharedInstance;

- (NSMutableArray *) dateArrayForCensus;
- (NSMutableArray *) dateArrayForAppts;

@end
