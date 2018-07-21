//
//  GenKeyPair.h
//  CCiPhoneApp
//
//  Created by Admin on 05/05/11.
//  Copyright 2011 Ardensys Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GenKeyPair : NSObject {

}
-(BOOL)GenerateKeyPair;
-(NSData*)PublicKey;

@end
