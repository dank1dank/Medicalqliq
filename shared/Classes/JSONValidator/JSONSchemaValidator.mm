//
//  JSONSchemaValidator.m
//  CCiPhoneApp
//
//  Created by Adam Sowa on 8/9/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#include <string>
#include "json_reader.h"
#include "json_schema_validator.h"
#import "JSONSchemaValidator.h"
#import "JSONKit.h"
#import "Log.h"

using base::Value;
using base::DictionaryValue;

int SchemeUnavailable = -1;

@implementation JSONSchemaValidator

+ (NSString *)embeddedSchema:(Schema)schema {
	static NSString *schemas[] = {
		@"register_account_request",
		@"register_account_response",        
		@"update_group_membership_request",
		@"update_group_membership_response",
		@"get_quick_messages_request",
		@"get_quick_messages_response",
		@"get_security_settings_request",
		@"get_security_settings_response",
		@"get_presence_status_request",
		@"get_presence_status_response",
		@"set_presence_status_request",
		@"set_presence_status_response",
		@"create_multiparty_request",
		@"create_multiparty_response",
		@"get_multiparty_request",
		@"get_multiparty_response",
		@"modify_multiparty_request",
		@"modify_multiparty_response",
		@"report_incident_request",
		@"report_incident_response",
        @"send_feedback_request",
        @"send_feedback_response",
		@"get_group_keypair_request",
		@"get_group_keypair_response",
        @"reset_password_request",
        @"reset_password_response",
        @"get_contact_pubkey_request",
        @"get_contact_pubkey_response",
		@"get_key_pair_request",
		@"get_key_pair_response",
		@"change_notifications",
		@"get_contact_info_request",
		@"get_contact_info_response",
		@"get_group_info_request",
		@"get_group_info_response",
		@"get_group_contacts_request",
		@"get_group_contacts_response",
		@"get_device_status_request",
		@"get_device_status_response",
		@"set_device_status_request",
		@"set_device_status_response",
		@"put_file_request",
		@"put_file_response",
		@"get_file_request",
		@"login_request",
		@"login_response",
		@"logout_request",
		@"logout_response",
		@"get_user_config_request",
		@"get_user_config_response",
		@"get_all_contacts_request",
		@"get_all_contacts_response",
        @"get_paged_contacts_request",
		@"get_paged_contacts_response",
		@"get_avatar_request",
		@"get_avatar_response",
		@"set_avatar_request",
		@"set_avatar_response",
		@"find_qliq_user_request",
		@"find_qliq_user_response",
		@"find_all_qliq_users_request",
		@"find_all_qliq_users_response",
		@"create_invitation_request",
		@"create_invitation_response",
		@"invitation_action_request",
		@"invitation_action_response",
		@"get_public_keys_request",
		@"get_public_keys_response",
		@"set_public_key_request",
		@"set_public_key_response",
		@"publickey-changed-notification",
		@"message",
        @"chat-message",
        @"update_profile_request",
        @"update_profile_response",
        @"update_password_request",
        @"update_password_response",
        @"get_escalated_callnotify_info_request",
        @"get_escalated_callnotify_info_response",
        @"update_escalated_callnotify_info_request",
        @"update_escalated_callnotify_info_responce",
        @"get_app_first_launch_info_request",
        @"get_app_first_launch_info_response",
        @"click2call_request"
	};
	static const int count = sizeof(schemas) / sizeof(schemas[0]);
	NSString *content = @"";
	
	if (-1 < schema && schema < count) {
		NSString* path = [[NSBundle mainBundle] pathForResource:schemas[schema] ofType:@"schema"];
		if (path != nil) {
			content = [NSString stringWithContentsOfFile:path
											  encoding:NSUTF8StringEncoding
												 error:NULL];
			if ([content length] == 0) {
				DDLogError(@"Empty schema resource for enum value: %d", schema);
			}
		} else {
			DDLogError(@"Cannot find schema resource for enum value: %d", schema);
		}
	} else {
		DDLogError(@"Requested schema enum value out of range: %d", schema);
	}
	return content;
}

+ (BOOL)validate:(NSString *)json embeddedSchema:(Schema)schema {

    if (schema == SchemeUnavailable) return YES;
    
	NSString *schemaString = [JSONSchemaValidator embeddedSchema:schema];
	return [JSONSchemaValidator validate:json embeddedSchemaString:schemaString];
}

+ (BOOL)validate:(NSString *)json embeddedSchemaString:(NSString *)schema {
	int errCode = 0;
	std::string errMsg;
	bool ignoreValidation = false;
    
	std::string cppJson = [json cStringUsingEncoding:NSUTF8StringEncoding];
	std::string cppSchema = [schema cStringUsingEncoding:NSUTF8StringEncoding];
	
    Value *schemaValue = JSONReader::ReadAndReturnError(cppSchema, false, &errCode, &errMsg);
    if (schemaValue == NULL) {
		DDLogError(@"Cannot parse schema: %d %s", errCode, errMsg.c_str());
        return false;
    }
    if (schemaValue->GetType() != Value::TYPE_DICTIONARY) {
        DDLogError(@"Schema root must be a dictionary");
		delete schemaValue;
        return false;
    }
	
    Value *jsonValue = JSONReader::ReadAndReturnError(cppJson, false, &errCode, &errMsg);
    if (jsonValue == NULL) {
        DDLogError(@"Cannot parse json: %d %s", errCode, errMsg.c_str());
        delete schemaValue;
        return false;
    }
	
    DictionaryValue *schemaDict = static_cast<DictionaryValue *>(schemaValue);
	
	base::JSONSchemaValidator validator(schemaDict);
    bool valid = validator.Validate(jsonValue);
	
    if (!valid) {
        const std::vector<base::JSONSchemaValidator::Error>& errors = validator.errors();
        for (std::size_t i = 0; i < errors.size(); ++i) {
            const base::JSONSchemaValidator::Error& err = errors[i];
			DDLogError(@"Validation error: %s: %s", err.path.c_str(), err.message.c_str());
        }
		
        //if (saveDebuggingInfoToDisk)
        //    debugSaveToDisk(json, schema, errors);
    }
	
	delete schemaValue;
	delete jsonValue;
	
    return valid || ignoreValidation;
}

+ (BOOL) errorInReply:(NSString *) jsonReply
{
	NSStringEncoding dataEncoding = NSUTF8StringEncoding;
	NSError *error=nil;
	
	NSData *jsonData = [jsonReply dataUsingEncoding:dataEncoding];
	
	JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
	NSString *errorMessage = [[jsonKitDecoder objectWithData:jsonData error:&error] objectForKey:@"Error"];
	
	if(errorMessage !=nil)
		return TRUE;
	else 
		return FALSE;
}

@end
