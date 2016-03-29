//
//  bigmlObjcTestCredentials.m
//  bigml-objc
//
//  Created by sergio on 29/03/16.
//  Copyright © 2016 BigML Inc. All rights reserved.
//

#import "bigmlObjcTestCredentials.h"

NSString* pathForResource(NSString* name) {
    for (NSBundle* bundle in [NSBundle allBundles]) {
        NSString* p = [bundle pathForResource:name ofType:nil];
        if (p)
            return p;
    }
    return nil;
}

@implementation bigmlObjcTestCredentials

+ (NSDictionary*)credentials {
    return [[NSDictionary alloc]
            initWithContentsOfFile:pathForResource(@"credentials.plist")];
}

+ (NSString*)username {
    return self.credentials[@"username"];
}

+ (NSString*)apiKey {
    return self.credentials[@"apiKey"];
}

@end
