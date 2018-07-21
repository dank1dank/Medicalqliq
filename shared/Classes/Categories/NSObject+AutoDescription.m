//
//  NSObject+AutoDescription.m
//
//  Created by Andrew on 26/3/11.
//  Copyright 2011 Al Digit. All rights reserved.
//

#import "NSObject+AutoDescription.h"
#import <objc/runtime.h>

@implementation NSObject(AutoDescription)

- (NSString *) autoDescriptionForClassType:(Class)classType { 
	
	NSMutableString * result = [NSMutableString string];
	
	// Find Out something about super Classes
	Class superClass  = class_getSuperclass(classType);
	if  ( superClass != nil && ![superClass isEqual:[NSObject class]])
	{
		[result appendString:[self autoDescriptionForClassType:superClass]];
	}
	
	// Add Information about Current Properties
	unsigned int property_count;
	objc_property_t * property_list = class_copyPropertyList(classType, &property_count); // Must Free
	
	for (NSInteger i = property_count - 1; i >= 0; --i) { // Reverse order, to get Properties in order they've defined
		objc_property_t property = property_list[i];
		
		const char * property_name = property_getName(property);
		
		NSString * propertyName = [NSString stringWithCString:property_name encoding:NSASCIIStringEncoding];
		if (propertyName) {
			id value = [self valueForKey:propertyName];
			
			[result appendFormat:@"	%@ = %@;\n", propertyName, value];
		}
	}
	free(property_list);
	
	return result;
}

// Reflects about self.
- (NSString *) autoDescription { 
	return [NSString stringWithFormat:@"[%@ {\n%@}]", NSStringFromClass([self class]), [self autoDescriptionForClassType:[self class]]];
}

@end


@implementation NSArray(AutoDescription)

- (NSString *) autoDescription {
    NSMutableString * result = [NSMutableString stringWithString:@"Array ["];
    
    for (id object in self) {
        [result appendString:[object autoDescription]];
        [result appendString:@",\n"];
    }
    [result appendString:@"]"];

    return result;
}

@end
