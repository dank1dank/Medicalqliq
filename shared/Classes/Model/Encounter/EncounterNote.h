//
//  EncounterNote.h
//  CCiPhoneApp
//
//  Created by Ravi Ada on 4/12/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EncounterNote : NSObject {
    /*
     CREATE TABLE encounter_note (
     id   integer PRIMARY KEY AUTOINCREMENT,
     encounter_id   integer,
     note_id             integer,
    FOREIGN KEY (encounter_id)
    REFERENCES encounter(id), 
    FOREIGN KEY (note_id)
    REFERENCES note(id)
    );     
     */
    NSInteger encounterNoteId;
    NSInteger encounterId;
    NSInteger typeId;
    NSString *type;
    NSString *textNote;
    NSData *voiceNote;
    NSData *pictureNote;
    NSTimeInterval lastUpdated;
    NSString *lastUpdatedUser;
    
	BOOL isDirty;
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readonly) NSInteger encounterNoteId;
@property (nonatomic, readwrite) NSInteger encounterId;
@property (nonatomic, readwrite) NSInteger typeId;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *textNote;
@property (nonatomic, retain) NSData *voiceNote;
@property (nonatomic, retain) NSData *pictureNote;

@property (nonatomic, assign) NSTimeInterval dateOfService;
@property (nonatomic, readwrite) NSTimeInterval lastUpdated;
@property (nonatomic, retain) NSString *lastUpdatedUser;

@property (nonatomic, readwrite) BOOL isDirty;
@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getEncounterNotesToDisplay:(NSInteger)encounterId;
+ (NSInteger) addEncounterNote:(EncounterNote *)encounterNote;
+ (BOOL) updateEncounterNote:(EncounterNote *)encounterNote;
+ (BOOL) deleteEncounterNote:(NSInteger)encounterNoteId;

//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;
- (NSMutableDictionary *) toDict;
@end


@interface NoteType : NSObject {
    NSInteger noteTypeId;
    NSString *description;
    
	BOOL isDetailViewHydrated;
    
}
@property (nonatomic, readwrite) NSInteger noteTypeId;
@property (nonatomic, retain) NSString *description;

@property (nonatomic, readwrite) BOOL isDetailViewHydrated;

//Static methods.
+ (NSMutableArray *) getNoteTypesToDisplay;
+ (NSInteger) addNoteType:(NoteType *)noteType;
+ (BOOL) deleteNoteType:(NSInteger)noteTypeId;
//Instance methods.
- (id) initWithPrimaryKey:(NSInteger)pk;

@end



