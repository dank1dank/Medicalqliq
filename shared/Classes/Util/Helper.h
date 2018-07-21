//
//  Helper.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/17/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Helper : NSObject

+ (NSArray *)getPastDates:(NSInteger)noOfDays;
+ (NSArray *)getFutureDates:(NSInteger)noOfDays;
+ (NSTimeInterval)conevrtDosToTimeInterval:(NSString *)dateOfService;

//+ (NSString *) getRaceGenderAgeStringForCensus: (Census_old *) censusObj;
//+ (NSString *) getRaceGenderAgeStringForPatient: (Patient_old *) patientObj;
//+ (NSString *) getRaceGenderAgeStringForAppt: (Appointment *) apptObj;

+ (NSInteger)age:(NSTimeInterval)dateOfBirth;
+ (NSDateFormatter*)getTimeFormatter;
+ (NSString *)getDateOfServiceInStringFormat:(NSDate *)dateOfSerice;
+ (NSString *)convertIntervalToDateString:(NSTimeInterval)timeInterval :(NSString *)formatStr;
+ (NSString *)getDateFromInterval:(NSTimeInterval)interval;


+ (NSTimeInterval)strDateToInterval:(NSString *)strDate :(NSString *)format;
+ (NSTimeInterval)strDateISO8601ToInterval:(NSString *)strDate;
+ (NSTimeInterval)strDateTimeISO8601ToInterval:(NSString *)strDate;
+ (NSString *)intervalToISO8601DateString:(NSTimeInterval)interval;
+ (NSString *)intervalToISO8601DateTimeString:(NSTimeInterval)interval;

+ (NSString *)getMyQliqId;
+ (void)setMyQliqId:(NSString *)aUsername;
+ (NSString *)getMacAddress UNAVAILABLE_ATTRIBUTE;

@end
