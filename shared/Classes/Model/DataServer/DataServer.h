//
//  DataServer.h
//  CCiPhoneApp
//
//  Created by Adam Sowa on 12/14/11.
//  Copyright (c) 2011 Ardensys Inc. All rights reserved.
//

#ifndef CCiPhoneApp_DataServer_h
#define CCiPhoneApp_DataServer_h

#define KEY_METADATA @"metadata"
#define KEY_ERROR_CURRENT_DOCUMENT @"currentDoc"

enum DataServerError {
    NoError,
    InvalidMetadataError,
    ObsoleteRevisionError,
    MongoDBConnectionError,
    InvalidInternalRevisionError
};


#endif
