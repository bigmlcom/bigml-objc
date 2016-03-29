//
//  bigmlObjcTestCredentials.h
//  bigml-objc
//
//  Created by sergio on 29/03/16.
//  Copyright © 2016 BigML Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* pathForResource(NSString* name);

@interface bigmlObjcTestCredentials : NSObject

+ (NSString*)username;
+ (NSString*)apiKey;

@end
