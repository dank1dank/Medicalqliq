//
//  EncounterNote.m
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import "EncounterNote.h"
#import "DBPersist.h"
#import "CensusSchema.h"

@implementation EncounterNote
@synthesize encounterNoteId,encounterId,typeId,type,textNote,voiceNote,pictureNote;
@synthesize isDirty,isDetailViewHydrated;
@synthesize dateOfService;
@synthesize lastUpdated, lastUpdatedUser;

+ (NSMutableArray *) getEncounterNotesToDisplay:(NSInteger)encounterId
{
    return [[DBPersist instance] getEncounterNotesToDisplay:encounterId];
}
+ (NSInteger) addEncounterNote:(EncounterNote *)encounterNote
{
    return [[DBPersist instance] addEncounterNote:encounterNote];
}
+ (BOOL) updateEncounterNote:(EncounterNote *)encounterNote
{
    return [[DBPersist instance] updateEncounterNote:encounterNote];
}
+ (BOOL) deleteEncounterNote:(NSInteger)encounterNoteId
{
    return [[DBPersist instance] deleteEncounterNote:encounterNoteId];
}


- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    encounterNoteId = pk;
    isDetailViewHydrated = NO;
    
    return self;
}

- (NSMutableDictionary *) toDict
{
    NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
    [dict setObject:type forKey:CENSUS_NOTES_TYPE];
    NSString *text = @"";
    if ([textNote length] > 0)
        text = textNote;
    [dict setObject:text forKey:CENSUS_NOTES_TEXT];
    
    return dict;
}

- (void) dealloc {
 	[type release];
    [textNote release];
    [voiceNote release];
    [pictureNote release];
	[super dealloc];
}
@end

@implementation NoteType
@synthesize noteTypeId,description,isDetailViewHydrated;

+ (NSMutableArray *) getNoteTypesToDisplay
{
    return [[DBPersist instance] getNoteTypesToDisplay];
}

+ (NSInteger) addNoteType:(NoteType *)noteType
{
    return [[DBPersist instance] addNoteType:noteType];
}

+ (BOOL) deleteNoteType:(NSInteger)noteTypeId
{
    return [[DBPersist instance] deleteNoteType:noteTypeId];
}


- (id) initWithPrimaryKey:(NSInteger) pk {
    
    [super init];
    noteTypeId = pk;
    isDetailViewHydrated = NO;
    
    return self;
}

- (void) dealloc {
 	[description release];
	[super dealloc];
}

@end
