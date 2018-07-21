//
//  CptUpdater.m
//  
//  Updater object that downloads the cpt file from the web and loads them SQLite database
//  

#import "CptUpdater.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "SVProgressHUD.h"
#import "CptDownloadViewController.h"
#import "QliqKeychainUtils.h"
#import "GetCptCsvRequestSchema.h"
#import "Log.h"
#import "JSONSchemaValidator.h"
#import "JSONKit.h"
#import "Helper.h"
#import "WebClient.h"
#import "UserSessionService.h"
#import "UserSession.h"

#define URL_LOAD_TIMEOUT 20.0
// Buffer size when reading from the file in bytes (=128 kbytes)
static const NSUInteger ReadBufferSize = 131072;
static const NSUInteger charactersToRemoveAtEnd=4;
static const NSUInteger paramQuantity=3;

@interface CptUpdater (Private)

// Main functions
- (void) parseCpts:(NSString*) filePath;
- (void) processCptFile:(NSString *) filePath;
- (void) parseMasterCptPft:(NSData *)MasterCptPftData;
- (void) parseNewCptCheck:(NSData *)CptInfoData;
- (NSUInteger) lineCountInCptFile:(NSString *) filePath;

// SQLite
- (NSUInteger) insertCptIntoDatabase:(NSArray *)cptRecord;
- (NSUInteger) insertMasterCptPftIntoDatabase:(NSArray *)masterCptPftRecord;

- (void) prepareDBAndQueries;
- (void) catMemoryDBToDisk;
- (void) finalizeQueries;
- (NSString *) documentsPath;
- (NSString *) databaseFilePath;
- (NSDictionary *) databaseCreationQueries;

// Utilities
- (NSInteger) epochForStringDate:(NSString *)stringDate;
- (void) notifyParseEndedTo:(id)receiver;

- (void)requestFinished:(ASIHTTPRequest *)request;
@end

#pragma mark -



#pragma mark SQLite statics

static sqlite3_stmt *insert_cpt_query = nil;
static sqlite3_stmt *insert_master_cpt_pft_query = nil;

#pragma mark -


@implementation CptUpdater

@synthesize delegate, viewController, updateAction, newCptsAvailable, statusMessage;
@synthesize isDownloading, downloadFailed, cptUpdateCheckURL, cptDataURL, statusCode, expectedContentLength, myConnection, receivedData;
@synthesize isParsing, mustAbortImport, parseFailed, cptCheck_cptUpdateTime, cptCheckFileSize, readyToLoadNumCpts, cptCreationDate, currentlyParsedNode, contentOfCurrentXMLNode, categoriesOfCurrentCpt, categoriesAlreadyInserted, numCptsParsed;

#pragma mark Utilities

- (void) notifyParseEndedTo:(id)receiver
{
	[receiver updater:self didEndActionSuccessful:!self.parseFailed];
}

- (NSString *) documentsPath
{
	
	NSArray *paths =
	NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return documentsDirectory;
}

- (NSString *) databaseFilePath
{
	UserSession *userSession = [UserSessionService currentUserSession];
	
	NSString *qliqId = userSession.sipAccountSettings.username;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *userDir = [documentsDirectory stringByAppendingFormat:@"/%@", qliqId];
    if(![fileManager fileExistsAtPath:userDir])
    {
        [fileManager createDirectoryAtPath:userDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *relativeDBPath = [NSString stringWithFormat:@"%@/%@.sqlite", qliqId, qliqId];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:relativeDBPath];
	
	/*
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *sqlPath = [documentsDirectory stringByAppendingPathComponent:@"qliq.sqlite"];
	*/
	return dbPath;
}

- (NSDictionary *) databaseCreationQueries
{
	NSDictionary *queries = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"CREATE TABLE cpt (code VARCHAR NOT NULL PRIMARY KEY,short_description VARCHAR,long_description text,version_year INTEGER)", @"createCptTable",
							 @"CREATE TABLE IF NOT EXISTS master_cpt_pft (cpt_code varchar(50), pft varchar(100))", @"createMasterCptPftTable", nil];
	
	return queries;
}

// converts US-style dates to epoch time (feed: @"3/28/1981")
- (NSInteger) epochForStringDate:(NSString *)stringDate
{
	NSInteger epoch = 0;
	[stringDate retain];
	
	// split the date
	NSArray *dateParts = [stringDate componentsSeparatedByString:@"/"];
	if ([dateParts count] >= 3) {
		NSUInteger month = [[dateParts objectAtIndex:0] intValue];
		NSUInteger day = [[dateParts objectAtIndex:1] intValue];
		NSUInteger year = [[dateParts objectAtIndex:2] intValue];
		
		year = (year < 100) ? ((year < 90) ? (year += 2000) : (year += 1900)) : year;
		
		// compose the date
		NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
		[components setYear:year];
		[components setMonth:month];
		[components setDay:day];
		
		// get the date
		NSCalendar *gregorianCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
		NSDate *date = [gregorianCalendar dateFromComponents:components];
		
		epoch = [date timeIntervalSince1970];
	}
	
	[stringDate release];
	
	return epoch;
}

#pragma mark SQLite
// Creates a writable copy of the bundled default database in the application Documents directory.
- (BOOL) connectToDBAndCreateIfNeeded
{
	return YES;
}

#pragma mark -

- (id) initWithDelegate:(id)myDelegate
{
	self = [super init];
	if (self) {
		self.delegate = myDelegate;
		self.updateAction = 1;				// 1 = load new check, 2 = download and install XML, 3 = load and install local XML
		self.receivedData = [NSMutableData data];
		mustAbortImport = NO;
		
		// NSBundle Info.plist
		NSDictionary *infoPlistDict = [[NSBundle mainBundle] infoDictionary];		// !! could use the supplied NSBundle or the mainBundle on nil
		self.cptUpdateCheckURL = [NSURL URLWithString:[infoPlistDict objectForKey:@"cptUpdateCheckURL"]];
		self.cptDataURL = [NSURL URLWithString:[infoPlistDict objectForKey:@"cptDataURL"]];
		//self.cptDataURL = [NSURL URLWithString:[infoPlistDict objectForKey:@"cptDownloadServiceURL"]];
		
	}
	
	return self;
}

- (void) dealloc
{
	self.delegate = nil;
	self.myConnection = nil;
	self.receivedData = nil;
	
	self.statusMessage = nil;
	self.cptUpdateCheckURL = nil;
	self.cptDataURL = nil;
	
	self.cptCreationDate = nil;
	self.currentlyParsedNode = nil;
	self.contentOfCurrentXMLNode = nil;
	self.categoriesOfCurrentCpt = nil;
	self.categoriesAlreadyInserted = nil;
	
	// SQLite
	[self finalizeQueries];
	
	[super dealloc];
}
#pragma mark -
#pragma mark Workhorse
- (void) startUpdaterAction
{
	self.mustAbortImport = NO;
	
	// action 1 and 2 start with a download
	if (updateAction <= 2) {
		self.isDownloading = YES;
		self.statusMessage = @"Downloading...";
		
		[delegate updaterDidStartAction:self];
		if (viewController) {
			[viewController updaterDidStartAction:self];
			if ([viewController respondsToSelector:@selector(updater:progress:)]) {
				[viewController updater:self progress:0.0];
			}
		}
		SipAccountSettings *sas= [UserSessionService currentUserSession].sipAccountSettings;
		NSURL *cptDownloadURL;
		if (2 == updateAction) {
			//url = self.cptDataURL;
			NSString *urlString = [[WebClient serverUrlForUsername:sas.username] stringByAppendingString:@"/services/get_cpt_csv"];
			cptDownloadURL = [NSURL URLWithString:urlString];
		}
		NSMutableDictionary *contentDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 @"*********", GET_CPT_CSV_REQUEST_MESSAGE_DATA_PASSWORD,
									 sas.username, GET_CPT_CSV_REQUEST_MESSAGE_DATA_USER_ID,
									 nil];
		NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								  contentDict, GET_CPT_CSV_REQUEST_MESSAGE_DATA,
								  GET_CPT_CSV_REQUEST_MESSAGE_TYPE_PATTERN, GET_CPT_CSV_REQUEST_MESSAGE_TYPE,
								  GET_CPT_CSV_REQUEST_MESSAGE_COMMAND_PATTERN, GET_CPT_CSV_REQUEST_MESSAGE_COMMAND,
								  GET_CPT_CSV_REQUEST_MESSAGE_SUBJECT_PATTERN, GET_CPT_CSV_REQUEST_MESSAGE_SUBJECT,
								  nil];
		NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								  dataDict, GET_CPT_CSV_REQUEST_MESSAGE,
								  nil];
		
		NSLog(@"%@",[jsonDict JSONString]);
		
		DDLogInfo(@"Sending get_cpt_csv request: %@", [jsonDict JSONString]);
		[contentDict setValue:sas.password forKey:GET_CPT_CSV_REQUEST_MESSAGE_DATA_PASSWORD];
		
		NSString *docsDir = [self documentsPath];
		
		// create the request and start downloading by making the connection
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:cptDownloadURL];
		
		[request appendPostData:[[jsonDict JSONString] dataUsingEncoding:NSUTF8StringEncoding]];
		NSString *postLength = [NSString stringWithFormat:@"%d", [[jsonDict JSONString] length]];
		[request addRequestHeader:@"Content-Type" value:@"application/json"];
		[request addRequestHeader:@"Content-Length" value:postLength];
		[request addRequestHeader:@"Accept" value:@"application/json"];
		[request setRequestMethod:@"POST"];
		[request setDownloadDestinationPath:[docsDir stringByAppendingPathComponent:@"my_cpt.csv"]];
        [request startSynchronous];
        [self requestFinished:request];
    
//		ASINetworkQueue *queue = [ASINetworkQueue queue];
//		[queue setRequestDidStartSelector:@selector(requestStarted:)];
//		[queue setRequestDidFailSelector:@selector(requestFailed:)];
//		[queue setRequestDidFinishSelector:@selector(requestFinished:)];
//		[queue addOperation:request];
//		[queue setDelegate:self];
//		[queue go];
	}
	
	// action 3 loads XML from disk
	else {
		readyToLoadNumCpts = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"numberOfIncludedCpts"] intValue];
		
		NSString *cptXMLPath = [NSBundle pathForResource:@"cpts" ofType:@"xml" inDirectory:[[NSBundle mainBundle] bundlePath]];
		NSData *includedXMLData = [NSData dataWithContentsOfFile:cptXMLPath];
		[self createCptsWithData:includedXMLData];
	}
}


// New cpt check. only runs a few milliseconds (XML has 2 child nodes...), so no extra thread and therefore no NSAutoreleasePool
- (void) parseNewCptCheck:(NSData *)XMLData
{
	self.isParsing = YES;
	self.statusMessage = nil;
	
	[delegate updaterDidStartAction:self];
	
	// Parse			****
	//[XMLData retain];
	//[self parseXMLData:XMLData parseError:nil];
	//[XMLData release];
	// Parse finished	****
	
	
	if (!cptCheck_cptUpdateTime) {
		self.parseFailed = YES;
		self.statusMessage = @"No cptCheck_cptUpdateTime!";
		self.statusMessage = @"No cptCheck_cptUpdateTime!";
		self.newCptsAvailable = NO;
	}
	
	// success, evaluate newCptsAvailable to YES when (availableCpts > usingCptsOf) or when no cpts are currently present
	else {
		self.parseFailed = NO;
		//NSInteger usingCptsOf = [APP_DELEGATE usingCptsOf];
		//self.newCptsAvailable = (0 == usingCptsOf) || (cptCheck_cptUpdateTime > usingCptsOf);
	}
	
	// inform the delegates
	self.isParsing = NO;
	[delegate updater:self didEndActionSuccessful:!self.parseFailed];
	self.updateAction = newCptsAvailable ? 2 : 1;
}

// call this to spawn a new thread which imports cpts from the XML
- (void) createCptsWithData
{
	self.isParsing = YES;
	self.statusMessage = @"Creating cpts...";
	
  //  [self performSelectorInBackground:@selector(updateDelegate:) withObject:self];
    [delegate updaterDidStartAction:self];
   
	//[delegate updaterDidStartAction:self];
    if (viewController) {
		[viewController updaterDidStartAction:self];
		if ([viewController respondsToSelector:@selector(updater:progress:)]) {
			[viewController updater:self progress:0.0];
		}
	}
	
	NSString *filePath = [[self documentsPath] stringByAppendingPathComponent:@"my_cpt.csv"];
	[self parseCpts:filePath];
	//[NSThread detachNewThreadSelector:@selector(parseCpts:) toTarget:self withObject:filePath];
}

#pragma mark Parser Delegate
- (void) processCptFile:(NSString *) filePath
{	
    self.statusMessage =  @"updating cpt table";
    
	// Get a handle for datafile
	NSFileHandle* dataFile = [NSFileHandle fileHandleForReadingAtPath: filePath];
	
    NSInteger size = [dataFile seekToEndOfFile];
    [dataFile seekToFileOffset:0];
	NSData* readData;
	NSString* dataString;
	NSArray* lineArray;
	NSArray* splitLine;
	NSUInteger lineArrayCount = 0;
    NSInteger bufferSize = ReadBufferSize;
    
	while (1) 
	{
		// create an autorelease pool so we will not run out of memory
		NSAutoreleasePool* loopPool = [[NSAutoreleasePool alloc] init];
		
		// read the chunk of data
		readData = [dataFile readDataOfLength: bufferSize];
		
		// exit the loop if no data is available
		if (!readData || [readData length] == 0)
		{
			[loopPool drain];			
			break;
		}
		
		dataString = [[NSString alloc] initWithData: readData encoding: NSASCIIStringEncoding];
        
		// divide read buffer into lines
		lineArray = [dataString componentsSeparatedByString: @"\n"];
		[dataString release];
        
		lineArrayCount += [lineArray count] - 1;
        
		// go through lines and add them into database. don't add the first line in file
		for (int i = 0; i < [lineArray count] - 1; i++)
		{
            NSString* singleLine = [[lineArray objectAtIndex: i] substringWithRange: NSMakeRange(1, [[lineArray objectAtIndex: i] length] - 1 - charactersToRemoveAtEnd)];
			splitLine = [singleLine componentsSeparatedByString: @"\",\""];
			
			splitLine = [NSArray arrayWithObjects: 
						 [splitLine objectAtIndex: 0],
						 [splitLine objectAtIndex: 2],
						 [splitLine objectAtIndex: 3], nil];
			
			if ([splitLine count] >= paramQuantity){
				[self insertCptIntoDatabase:splitLine];
                numCptsParsed ++;
            }
		}
		// seek back to the beginning of the last line
		NSString* lastLine = [lineArray lastObject];
        [dataFile seekToFileOffset: [dataFile offsetInFile] - [lastLine length]];
        
		// show progress and flush the innerPool
		//if (0 == lineArrayCount % 50) {
      
        double offset = [dataFile offsetInFile];
        double fraction = offset/size;
        [self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:fraction+0.5] waitUntilDone:NO];
		//}
        
        
        // if there is no endline, read more next time
        if ([lineArray count] == 1)
        {
            bufferSize *= 2;
        }
		
		// drain autorelease pool
		[loopPool drain];
	}    
	// Close a file
	[dataFile closeFile];
	
}

// will detach this thread from the main thread - create our own NSAutoreleasePool
- (void) parseCpts:(NSString *) filePath
{
	NSAutoreleasePool *myAutoreleasePool = [[NSAutoreleasePool alloc] init];
	
	numCptsParsed = 0;
	[self prepareDBAndQueries];
	
	// Parse and create			****
	DDLogSupport(@"CPT download begin...");
	//* --
	sqlite3_stmt *begin_transaction_stmt;
	const char *beginTrans = "BEGIN EXCLUSIVE TRANSACTION";
	if (sqlite3_prepare_v2(memory_database, beginTrans, -1, &begin_transaction_stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: Failed to prepare exclusive transaction: '%s'.", sqlite3_errmsg(memory_database));
	}
	if (SQLITE_DONE != sqlite3_step(begin_transaction_stmt)) {
		NSAssert1(0, @"Error: Failed to step on begin_transaction_stmt: '%s'.", sqlite3_errmsg(memory_database));
	}
	sqlite3_finalize(begin_transaction_stmt);
	
	// --	*/
	[self processCptFile:filePath];			// does the parsing and inserting into memory_database
	//* --
	
	sqlite3_stmt *end_transaction_stmt;
	const char *endTrans = "COMMIT";
	if (sqlite3_prepare_v2(memory_database, endTrans, -1, &end_transaction_stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to commit transaction: '%s'.", sqlite3_errmsg(memory_database));
	}
	if (SQLITE_DONE != sqlite3_step(end_transaction_stmt)) {
		NSAssert1(0, @"Error: Failed to step on end_transaction_stmt: '%s'.", sqlite3_errmsg(memory_database));
	}
	sqlite3_finalize(end_transaction_stmt);
	// --	*/
	DDLogSupport(@"CPT download end...");
	// Parsing done				****
	
	
	self.parseFailed = NO;
	[self catMemoryDBToDisk];			// concatenates memory_database to the file database and closes memory_database
	
	// Clean up
	self.newCptsAvailable = NO;
	
	[self performSelectorOnMainThread:@selector(notifyParseEndedTo:) withObject:delegate waitUntilDone:YES];
	self.updateAction = parseFailed ? updateAction : 1;
    
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
	
	[myAutoreleasePool release];
}
#pragma mark -

#pragma mark Download delegate
- (void)requestStarted:(ASIHTTPRequest *)request {
    self.statusMessage = NSLocalizedString(@"Getting AMA CPT File", @"Getting AMA CPT File");
}

- (void)requestFailed:(ASIHTTPRequest *)request {
	DDLogError(@"Cannot send cpt download request to the server");
	self.statusMessage = NSLocalizedString(@"Network authentication failed", @"File Fetch failed!");
     [delegate updater:self didEndActionSuccessful:NO];
}

- (void)requestFinished:(ASIHTTPRequest *)request {
     [self performSelectorOnMainThread:@selector(updateProgress:) withObject:[NSNumber numberWithFloat:0.5] waitUntilDone:NO];
	int httpStatusCode = [request responseStatusCode];
	if(httpStatusCode==200){
		// the update-check file, let's see if we need to update
		if (1 == updateAction) {
			[self parseNewCptCheck:receivedData];
		}
		// parse the data - we received the cpts, hooray!
		else {
			NSString *filePath = [[self documentsPath] stringByAppendingPathComponent:@"my_cpt.csv"];
			if([self lineCountInCptFile:filePath]>1){
				DDLogSupport(@"Got the cpt file!");
				self.statusMessage = NSLocalizedString(@"Got the file!", @"Got the file!");
				[self createCptsWithData];
			}else{
				DDLogError(@"CPT file has invalid data");
				self.statusMessage = @"CPT file has invalid data";//[NSString stringWithFormat:@"%@ %@",@"Error :",[request.error description]];
				[delegate updater:self didEndActionSuccessful:NO];
			}
		}
	}else{
        DDLogError(@"Cannot get CPT file, http status: %d", httpStatusCode);
		self.statusMessage = @"Network connection failed";//[NSString stringWithFormat:@"%@ %@",@"Error :",[request.error description]];
        [delegate updater:self didEndActionSuccessful:NO];
	}
}
- (void) updateProgress:(NSNumber *)progress
{
	if ([delegate respondsToSelector:@selector(updater:progress:)]) {
		[delegate updater:self progress:[progress floatValue]];
	}
	if ([viewController respondsToSelector:@selector(updater:progress:)]) {
		[viewController updater:self progress:[progress floatValue]];
	}
}

#pragma mark SQLite

- (NSUInteger) insertCptIntoDatabase:(NSArray *)cptRecord
{
	if (!memory_database) {
		NSAssert(0, @"memory_database is not present!");
	}
	
	[cptRecord retain];
	NSInteger insert_cpt_id = 0;
	
	// Insert the cpt **
	sqlite3_bind_text(insert_cpt_query, 1, [[cptRecord objectAtIndex:0] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_cpt_query, 2, [[cptRecord objectAtIndex:1] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(insert_cpt_query, 3, [[cptRecord objectAtIndex:2] UTF8String], -1, SQLITE_TRANSIENT);
	
	if (SQLITE_DONE == sqlite3_step(insert_cpt_query)) {
		insert_cpt_id = sqlite3_last_insert_rowid(memory_database);
	}
	else {
		NSAssert2(0, @"Error: Failed to insert cpt %@: '%s'.", [cptRecord objectAtIndex:0], sqlite3_errmsg(memory_database));
	}
	sqlite3_reset(insert_cpt_query);
	[cptRecord release];
	
	return insert_cpt_id;
}

// Call before we start to parse
- (void) prepareDBAndQueries
{
	char *err;
	
	// ****
	// Create the in-memory database (for faster insert operation)
	if (SQLITE_OK == sqlite3_open(":memory:", &memory_database)) {		// sqlite3_open_v2(":memory:", &memory_database, SQLITE_OPEN_CREATE, NULL)
		NSDictionary *creationQueries = [self databaseCreationQueries];
		NSString *createCptTable = [creationQueries objectForKey:@"createCptTable"];
		NSString *createMasterCptPftTable = [creationQueries objectForKey:@"createMasterCptPftTable"];
		
		sqlite3_exec(memory_database, [createCptTable UTF8String], NULL, NULL, &err);
		if (err) {
			NSAssert1(0, @"Error: Failed to execute createCptTable: '%s'.", sqlite3_errmsg(memory_database));
		}
		
		sqlite3_exec(memory_database, [createMasterCptPftTable UTF8String], NULL, NULL, &err);
		if (err) {
			NSAssert1(0, @"Error: Failed to execute createMasterCptPftTable: '%s'.", sqlite3_errmsg(memory_database));
		}
		
		
	}
	else {
		sqlite3_close(memory_database);
		NSAssert1(0, @"Failed to open new memory_database: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	
	// ****
	// prepare statements
	const char *qry1 = "INSERT INTO cpt (code,short_description,long_description) VALUES (?,?,?)";
	if (sqlite3_prepare_v2(memory_database, qry1, -1, &insert_cpt_query, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare insert_cpt_query: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	const char *qry2 = "INSERT INTO master_cpt_pft (cpt_code, pft) VALUES (?, ?)";
	if (sqlite3_prepare_v2(memory_database, qry2, -1, &insert_master_cpt_pft_query, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare insert_linker_query: '%s'.", sqlite3_errmsg(memory_database));
	}
	
}


// empties the old database and fills it from the memory database
- (void) catMemoryDBToDisk
{
	UserSession *userSession = [UserSessionService currentUserSession];

	self.statusMessage = @"Finishing...";
	[delegate updaterDidStartAction:self];
	
	// ****
	// empty current database
	char *err;
	/*
	 sqlite3_exec(database, "DELETE FROM cpt", NULL, NULL, &err);
	 if (err) {
	 NSAssert1(0, @"Error: Failed to empty categories table: '%s'.", sqlite3_errmsg(database));
	 }
	 
	 sqlite3_exec(database, "DELETE FROM master_cpt_pft", NULL, NULL, &err);
	 if (err) {
	 NSAssert1(0, @"Error: Failed to empty category_cpt_linker table: '%s'.", sqlite3_errmsg(database));
	 }*/
	
	// ****
	// ATTACH main database to :memory: database
	NSString *sqlPath = [self databaseFilePath];
	//NSString *attach_qry = [NSString stringWithFormat:@"ATTACH DATABASE \"%@\" AS real_db KEY \'%@\'", sqlPath,userSession.dbKey];

    NSMutableString *attach_qry = [NSMutableString stringWithFormat:@"ATTACH DATABASE \"%@\" AS real_db", sqlPath];
	NSLog(@"%@",userSession.dbKey);
    if(userSession.dbKey != nil)
    {
        [attach_qry appendFormat:@" KEY \'%@\'", userSession.dbKey];
    }
    
	sqlite3_exec(memory_database, [attach_qry UTF8String], NULL, NULL, &err);
	if (err) {
		NSAssert1(0, @"Error: failed to ATTACH DATABASE: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	// INSERT cpt and master_cpt_pft and link them
	sqlite3_exec(memory_database, "INSERT INTO real_db.cpt SELECT * FROM main.cpt", NULL, NULL, &err);
    DDLogError(@"%s", err);
	if (err) {
		NSAssert1(0, @"Error: failed to cat cpt to the real database: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	sqlite3_exec(memory_database, "INSERT INTO real_db.master_cpt_pft SELECT * FROM main.master_cpt_pft", NULL, NULL, &err);
    DDLogError(@"%s", err);
	if (err) {
		NSAssert1(0, @"Error: failed to cat master_cpt_pft to the real database: '%s'.", sqlite3_errmsg(memory_database));
	}
	
	[self finalizeQueries];
}


- (void) finalizeQueries
{
	if (insert_cpt_query) {
		sqlite3_finalize(insert_cpt_query);
		insert_cpt_query = nil;
	}
	if (insert_master_cpt_pft_query) {
		sqlite3_finalize(insert_master_cpt_pft_query);
		insert_master_cpt_pft_query = nil;
	}
	if (memory_database) {
		sqlite3_close(memory_database);
		memory_database = nil;
	}
}
#pragma mark -

- (NSUInteger) lineCountInCptFile:(NSString *) filePath
{
	NSFileHandle * file = [NSFileHandle fileHandleForReadingAtPath:filePath];
	NSUInteger chunkSize = 1024;
	NSData * chunk = [file readDataOfLength:chunkSize];
	NSUInteger numberOfNewlines = 0;
	while ([chunk length] > 0) {
		const unichar * bytes = (const unichar *)[chunk bytes];
		for (int index = 0; index < [chunk length]; ++index) {
			unichar character = (unichar)bytes[index];
			if ([[NSCharacterSet newlineCharacterSet] characterIsMember:character]) {
				numberOfNewlines++;
			}
		}
		chunk = [file readDataOfLength:chunkSize];
	}
	return numberOfNewlines;
}
@end
