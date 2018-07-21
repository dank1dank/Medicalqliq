//
//  CptUpdater.h
//  
//  Updater object that downloads the cpt file from the web and loads them SQLite database
//  


#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import "CptUpdaterDelegate.h"
@class CptDownloadViewController;

@interface CptUpdater : NSObject {
	id<CptUpdaterDelegate> delegate;
	CptDownloadViewController<CptUpdaterDelegate> *viewController;
	
	sqlite3 *database;
	sqlite3 *memory_database;
	
	BOOL newCptsAvailable;
	NSUInteger updateAction;				// 1 = check, 2 = download and install
	NSString *statusMessage;
	
	// Downloading
	BOOL isDownloading;
	BOOL downloadFailed;
	NSURL *cptUpdateCheckURL;
	NSURL *cptDataURL;
	NSInteger statusCode;					// Server response code
	long long expectedContentLength;
	
	NSURLConnection *myConnection;
	NSMutableData *receivedData;
	
	// Parsing
	BOOL isParsing;
	BOOL mustAbortImport;
	BOOL parseFailed;
	NSAutoreleasePool *innerPool;
	NSInteger cptCheck_cptUpdateTime;
	NSInteger cptCheckFileSize;
	
	NSUInteger readyToLoadNumCpts;
	
	NSDate *cptCreationDate;
	NSUInteger numCptsParsed;
}

@property (nonatomic, assign) CptDownloadViewController *viewController;

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) NSUInteger updateAction;

@property (nonatomic, assign) BOOL newCptsAvailable;
@property (nonatomic, retain) NSString *statusMessage;

// Downloading
@property (nonatomic, assign) BOOL isDownloading;
@property (nonatomic, assign) BOOL downloadFailed;
@property (nonatomic, retain) NSURL *cptUpdateCheckURL;
@property (nonatomic, retain) NSURL *cptDataURL;

@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, assign) long long expectedContentLength;

@property (nonatomic, retain) NSURLConnection *myConnection;
@property (nonatomic, retain) NSMutableData *receivedData;

// Parsing
@property (nonatomic, assign) BOOL isParsing;
@property (nonatomic, assign) BOOL mustAbortImport;
@property (nonatomic, assign) BOOL parseFailed;
@property (nonatomic, assign) NSInteger cptCheck_cptUpdateTime;
@property (nonatomic, assign) NSInteger cptCheckFileSize;

@property (nonatomic, assign) NSUInteger readyToLoadNumCpts;

@property (nonatomic, retain) NSDate *cptCreationDate;
@property (nonatomic, retain) NSMutableDictionary *currentlyParsedNode;
@property (nonatomic, retain) NSMutableString *contentOfCurrentXMLNode;
@property (nonatomic, retain) NSMutableArray *categoriesOfCurrentCpt;
@property (nonatomic, retain) NSMutableDictionary *categoriesAlreadyInserted;
@property (nonatomic, assign) NSUInteger numCptsParsed;

- (id) initWithDelegate:(id) myDelegate;
- (void) startUpdaterAction;
- (void) createCptsWithData:(NSData *)XMLData;
- (BOOL) connectToDBAndCreateIfNeeded;

@end
