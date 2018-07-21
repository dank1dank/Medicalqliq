//
//  Helper.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/17/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "Helper.h"
#import "QliqKeychainUtils.h"
#import "NSDate+Helper.h"
#import "ISO8601DateFormatter.h"
#import "Taxonomy.h"
#import "UserSessionService.h"
#import "UserSession.h"
#import "QliqUserDBService.h"
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

static NSString *s_qliqId = nil;

@implementation Helper
/*+ (NSMutableArray *) getDates:(NSInteger) noOfDays
{
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateFormat:@"MM/dd/yy"];
	NSMutableArray *pickerDatesArray = [[[NSMutableArray alloc] init] autorelease];
	
	// set up date components
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	// create a calendar
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	
	for(int i=0;i<=noOfDays;i++){
		[components setDay:-i];
		NSDate *newDate2 = [gregorian dateByAddingComponents:components toDate:[NSDate dateWithoutTime] options:0];
		NSString *dateString = [format stringFromDate:newDate2];
		//DDLogSupport(@"Clean: %@", dateString);
		[pickerDatesArray addObject:dateString];
	}
    return pickerDatesArray;
}*/

// MZ create array with future dates
/*+ (NSMutableArray *) getFutureDates:(NSInteger) noOfDays
{
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateFormat:@"MM/dd/yy"];
	NSMutableArray *pickerViewArray = [[NSMutableArray alloc] init];
	
	// set up date components
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	// create a calendar
	NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	
	for(int i=noOfDays;i>0;i--){
		[components setDay:i];
		NSDate *newDate2 = [gregorian dateByAddingComponents:components toDate:[NSDate dateWithoutTime] options:0];
		NSString *dateString = [format stringFromDate:newDate2];
		//DDLogSupport(@"Clean: %@", dateString);
		[pickerViewArray addObject:dateString];
	}
    return [pickerViewArray autorelease];
}*/

+(NSArray*) getPastDates:(NSInteger)noOfDays
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] initWithCapacity:noOfDays];
    
    NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    NSDate *today = [NSDate dateWithoutTime];
    for(int i=1; i<noOfDays - 1; i++)
    {
		[components setDay:-i];
		NSDate *date = [gregorianCal dateByAddingComponents:components toDate:today options:0];
		[mutableRez addObject:date];
	}
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    [gregorianCal release];
    [components release];
    return rez;
}

+(NSArray*) getFutureDates:(NSInteger) noOfDays
{
    NSMutableArray *mutableRez = [[NSMutableArray alloc] initWithCapacity:noOfDays];
    
    NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    NSDate *today = [NSDate dateWithoutTime];
    for(NSInteger i=noOfDays; i>0; i--)
    {
		[components setDay:i];
		NSDate *date = [gregorianCal dateByAddingComponents:components toDate:today options:0];
		[mutableRez addObject:date];
	}
    
    NSArray *rez = [NSArray arrayWithArray:mutableRez];
    [mutableRez release];
    [gregorianCal release];
    [components release];
    return rez;
}




+ (NSTimeInterval) conevrtDosToTimeInterval:(NSString *)dateOfService
{
    NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setDateFormat:@"MM/dd/yy"];
    [format setTimeZone:[NSTimeZone localTimeZone]];
    NSTimeInterval dosInterval = [[format dateFromString:dateOfService] timeIntervalSince1970];
    return dosInterval;
}

/*
+ (NSString *) getRaceGenderAgeStringForCensus:(Census_old *)censusObj
{
    NSString *thisGender = censusObj.gender==nil ? @"" : [[censusObj.gender substringToIndex:1] uppercaseString];
    NSString *thisRace = censusObj.race==nil ? @"" : [[censusObj.race substringToIndex:1] uppercaseString];
    NSInteger age = censusObj.dateOfBirth==0 ? 0 : [Helper age:censusObj.dateOfBirth];
    NSString *retVal;
    if (age>0)
        retVal=[NSString stringWithFormat:@"%d%@%@",age,thisGender,thisRace];
    else
        retVal=[NSString stringWithFormat:@"%@%@",thisGender,thisRace];
    return retVal;
}

+ (NSString *) getRaceGenderAgeStringForPatient:(Patient_old *)patientObj
{
    NSString *thisGender = patientObj.gender==nil ? @"" : [[patientObj.gender substringToIndex:1] uppercaseString];
    NSString *thisRace = patientObj.race==nil ? @"" : [[patientObj.race substringToIndex:1] uppercaseString];
    NSInteger age = patientObj.dateOfBirth==0 ? 0 : [Helper age:patientObj.dateOfBirth];
    NSString *retVal;
    if (age>0)
        retVal=[NSString stringWithFormat:@"%d%@%@",age,thisGender,thisRace];
    else
        retVal=[NSString stringWithFormat:@"%@%@",thisGender,thisRace];
    return retVal;
}

+ (NSString *) getRaceGenderAgeStringForAppt:(Appointment *)apptObj
{
    NSString *thisGender = apptObj.gender==nil ? @"" : [[apptObj.gender substringToIndex:1] uppercaseString];
    NSString *thisRace = apptObj.race==nil ? @"" : [[apptObj.race substringToIndex:1] uppercaseString];
    NSInteger age = apptObj.dateOfBirth==0 ? 0 : [Helper age:apptObj.dateOfBirth];
    NSString *retVal;
    if (age>0)
        retVal=[NSString stringWithFormat:@"%d%@%@",age,thisGender,thisRace];
    else
        retVal=[NSString stringWithFormat:@"%@%@",thisGender,thisRace];
    return retVal;
}

*/

+ (NSInteger)age:(NSTimeInterval)dateOfBirth 
{
	NSInteger myage=0;
	if(dateOfBirth != 0){
		NSCalendar *calendar = [NSCalendar currentCalendar];
		unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
		NSDateComponents *dateComponentsNow = [calendar components:unitFlags fromDate:[NSDate dateWithoutTime]];
		NSDateComponents *dateComponentsBirth = [calendar components:unitFlags fromDate:[NSDate dateWithTimeIntervalSince1970: dateOfBirth]];
		
		if (([dateComponentsNow month] < [dateComponentsBirth month]) ||
			(([dateComponentsNow month] == [dateComponentsBirth month]) && ([dateComponentsNow day] < [dateComponentsBirth day]))) {
			myage = [dateComponentsNow year] - [dateComponentsBirth year] - 1;
		} else {
			myage = [dateComponentsNow year] - [dateComponentsBirth year];
		}
	}
	return myage;
	
}

+ (NSDateFormatter*) getTimeFormatter
{
    NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [timeFormatter setDateFormat:@"hh:mm a"];
    [timeFormatter setLocale:[NSLocale currentLocale]];
    [timeFormatter setTimeZone:[NSTimeZone localTimeZone]];
    return timeFormatter;
}
+ (NSString *) getDateOfServiceInStringFormat:(NSDate*) dateOfSerice
{
    NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setDateFormat:@"MM/dd/yy"];
    return [format stringFromDate:dateOfSerice];
}

+ (NSString *) convertIntervalToDateString : (NSTimeInterval) timeInterval :(NSString*) formatStr
{
	NSString *datestr=nil;
	if(timeInterval != 0){
		NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
		[format setDateFormat:formatStr];
		datestr =  [format stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeInterval]];
	}
	return datestr;
}

+ (NSString *)getDateFromInterval:(NSTimeInterval)interval {
	NSString *datestr = nil;
	if(interval != 0){
		NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
		[format setDateFormat:@"MM/dd/yyyy"];
		datestr =  [format stringFromDate:[NSDate dateWithTimeIntervalSince1970:interval]];
	}
	return datestr;
}

+ (NSTimeInterval) strDateToInterval :(NSString *) strDate :(NSString *) format
{
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:format];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    NSTimeInterval dosInterval = [[formatter dateFromString:strDate] timeIntervalSince1970];
    return dosInterval;
}

+ (NSTimeInterval) strDateISO8601ToInterval:(NSString *) strDate
{
    if ([strDate length] == 0)
        return 0;
    
    ISO8601DateFormatter *formatter = [[[ISO8601DateFormatter alloc] init] autorelease];
    formatter.includeTime = NO;
    NSTimeInterval dosInterval = [[formatter dateFromString:strDate] timeIntervalSince1970];
    return dosInterval;
}

+ (NSTimeInterval) strDateTimeISO8601ToInterval:(NSString *) strDate
{
    if ([strDate length] == 0)
        return 0;
    
    ISO8601DateFormatter *formatter = [[[ISO8601DateFormatter alloc] init] autorelease];
    formatter.includeTime = YES;
    NSTimeInterval dosInterval = [[formatter dateFromString:strDate] timeIntervalSince1970];
    return dosInterval;
}

+ (NSString *) intervalToISO8601DateString:(NSTimeInterval)interval
{
    ISO8601DateFormatter *formatter = [[[ISO8601DateFormatter alloc] init] autorelease];
    formatter.includeTime = NO;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    return [formatter stringFromDate:date];
}

+ (NSString *) intervalToISO8601DateTimeString:(NSTimeInterval)interval
{
    ISO8601DateFormatter *formatter = [[[ISO8601DateFormatter alloc] init] autorelease];
    formatter.includeTime = YES;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    return [formatter stringFromDate:date];
}

+ (NSString *) getMyQliqId
{
	
    if ([s_qliqId length] == 0)
    {
        [Helper setMyQliqId: [UserSessionService currentUserSession].user.qliqId];
    }
	
	return s_qliqId;	
}

+ (void) setMyQliqId:(NSString *)aQliqId
{
    if (s_qliqId != aQliqId)
    {
        [s_qliqId release];
        s_qliqId = [aQliqId retain];
    }
}

@end
