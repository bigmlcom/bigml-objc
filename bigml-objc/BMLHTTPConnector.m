// Copyright 2015-2016 BigML
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License. You may obtain
// a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import "BMLHTTPConnector.h"
//#import "NSError+BMLError.h"
#import "NSMutableData+BMLData.h"
#import "BMLHTTPMethodHandler.h"

@implementation BMLHTTPConnector {
    
    BMLHTTPMethodHandler* _getter;
    BMLHTTPMethodHandler* _poster;
    BMLHTTPMethodHandler* _putter;
    BMLHTTPMethodHandler* _deleter;
    BMLHTTPMethodHandler* _uploader;
    
    NSString* _boundary;
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        _boundary = @"---------------------------14737809831466499882746641449";

        _getter = [[BMLHTTPMethodHandler alloc] initWithMethod:@"GET"
                                                  expectedCode:200];
        _poster = [[BMLHTTPMethodHandler alloc] initWithMethod:@"POST"
                                                  expectedCode:201];
        _putter = [[BMLHTTPMethodHandler alloc] initWithMethod:@"PUT"
                                                  expectedCode:202];
        _deleter = [[BMLHTTPMethodHandler alloc] initWithMethod:@"DELETE"
                                                  expectedCode:204];
        _uploader = [[BMLHTTPMethodHandler alloc] initWithMethod:@"POST"
                                                  expectedCode:201
                                                     contentType:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", _boundary]];
    }
    return self;
}

- (void)getURL:(NSURL*)url
    completion:(void(^)(NSDictionary*, NSError*))completion {
    
    [_getter runWithURL:url body:nil completion:^(NSDictionary* dict, NSError* e) {
        if (completion)
            completion(dict, e);
    }];
}

- (void)postURL:(NSURL*)url
           body:(NSDictionary*)body
     completion:(void(^)(NSDictionary*, NSError*))completion {
    
    [_poster runWithURL:url body:body completion:completion];
}

- (void)putURL:(NSURL*)url
          body:(NSDictionary*)body
    completion:(void(^)(NSError*))completion {
    
    [_putter runWithURL:url body:body completion:^(NSDictionary* dict, NSError* e) {
        if (completion) {
            completion(e);
        }
    }];
}

- (void)deleteURL:(NSURL*)url
       completion:(void(^)(NSError*))completion {
    
    [_deleter runWithURL:url body:nil completion:^(NSDictionary* dict, NSError* e) {
        if (completion) {
            completion(e);
        }
    }];
}

- (void)uploadURL:(NSURL*)url
         filename:(NSString*)filename
         filepath:(NSString*)filepath
             body:(NSDictionary*)body
       completion:(void(^)(NSDictionary*, NSError*))completion {
    
    NSMutableData* bodyData = [NSMutableData new];
    NSString* boundary = @"---------------------------14737809831466499882746641449";
    for (NSString* key in body.allKeys) {
        NSObject* value = body[key];
        NSError* error = nil;
        NSData* fieldData = [NSJSONSerialization dataWithJSONObject:value
                                                            options:0
                                                              error:&error];
        NSString* stringValue = [[NSString alloc] initWithData:fieldData
                                                      encoding:NSUTF8StringEncoding];
        if (stringValue) {
            [bodyData appendStringWithFormat:@"\r\n--%@r\n", boundary];
            [bodyData appendStringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n",
             key];
            [bodyData appendStringWithFormat:@"\r\n%@", value];
        } else {
            NSAssert(NO, @"Could not convert body field: %@", value);
        }
    }
    [bodyData appendStringWithFormat:@"\r\n--%@r\n", boundary];
    [bodyData appendStringWithFormat:
     @"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", filename];
    [bodyData appendStringWithFormat:@"Content-Type: application/octet-stream\r\n\r\n"];
    [bodyData appendData:[NSData dataWithContentsOfFile:filepath]];
    [bodyData appendStringWithFormat:@"\r\n--%@r\n", boundary];

    [_uploader runWithURL:url data:bodyData completion:completion];
}

@end












