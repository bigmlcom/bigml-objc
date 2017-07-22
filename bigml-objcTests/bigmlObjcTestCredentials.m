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
    NSDictionary* creds = [[NSDictionary alloc]
            initWithContentsOfFile:pathForResource(@"credentials.plist")];
    
    NSAssert(![creds[@"apiKey"] isEqualToString:@"your-api-key"] &&
             ![creds[@"username"] isEqualToString:@"your-username"],
             @"You shouldp provide your access credentials in credentials.plist");
    return creds;
}

+ (NSString*)username {
    return self.credentials[@"username"];
}

+ (NSString*)apiKey {
    return self.credentials[@"apiKey"];
}

@end
