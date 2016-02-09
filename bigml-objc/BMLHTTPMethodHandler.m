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

#import "BMLHTTPMethodHandler.h"
#import "NSError+BMLError.h"

@implementation NSHTTPURLResponse (isStrictlyValid)

- (BOOL)isStrictlyValid {
    return self.statusCode >= 200 && self.statusCode <= 206;
}

@end

@implementation BMLHTTPMethodHandler {
    
    NSString* _method;
    NSUInteger _expectedCode;
    NSString* _contentType;
    NSURLSession* _session;
}

- (instancetype)initWithMethod:(NSString*)method
                  expectedCode:(NSUInteger)expectedCode
                   contentType:(NSString*)contentType {
    
    if (self = [super init]) {
        _method = method;
        _expectedCode = expectedCode;
        _contentType = contentType;
    }
    return self;
}

- (instancetype)initWithMethod:(NSString*)method
                  expectedCode:(NSUInteger)expectedCode {
    
    return  [self initWithMethod:method
                    expectedCode:expectedCode
                     contentType:@"application/json; charset=utf-8"];
}

- (void)runWithURL:(NSURL*)url
              data:(NSData*)data
        completion:(void(^)(NSDictionary*, NSError*))completion {
    
    [self handleDataRequestWithMethod:_method
                                  url:url
                                 data:data
                              handler:^(NSData* data, NSError* error) {
                                  
                                  NSDictionary* jsonDict = nil;
                                  if (!error && data.length > 0)
                                      jsonDict = [self responseDictFromData:data
                                                               expectedCode:_expectedCode
                                                                      error:&error];
                                  if (completion)
                                      completion(jsonDict, error);
                              }];
}

- (void)runWithURL:(NSURL*)url
              body:(NSDictionary*)body
        completion:(void(^)(NSDictionary*, NSError*))completion {
    
    NSError* error = nil;
    NSData* data = nil;
    if (body.count > 0) {

        data = [NSJSONSerialization dataWithJSONObject:body
                                               options:0
                                                 error:&error];
        if (!data) {
            if (completion)
                completion(@{}, error);
            return;
        }
    }
    [self runWithURL:url data:data completion:completion];
}

- (NSURLSession*)session {
    
    if (!_session) {
        NSURLSessionConfiguration* conf =
        [NSURLSessionConfiguration ephemeralSessionConfiguration];
        conf.HTTPAdditionalHeaders = @{@"Content-Type" : @"application/json"};
        _session = [NSURLSession sessionWithConfiguration:conf];
    }
    return _session;
}

- (NSString*)stringFromOptions:(NSDictionary*)options {
    
    NSString* result = @"";
    for (NSString* value in options.allValues) {
        if ([value length] > 0) {
            //            NSString* trimmedOption =
            //            [value substringWithRange:NSMakeRange()
            result = [NSString stringWithFormat:@"%@, %@", result, value];
        }
    }
    return result;
}

- (void)dataWithRequest:(NSURLRequest*)request
             completion:(void(^)(NSData* data, NSError* error))completion {
    
    [[self.session dataTaskWithRequest:request
                     completionHandler:^(NSData* data, NSURLResponse* resp, NSError* error) {
                         if (!error) {
                             if ([resp isKindOfClass:[NSHTTPURLResponse class]]) {

                                 NSHTTPURLResponse* response = (id)resp;
                                 if (![response isStrictlyValid]) {
                                     
                                     NSUInteger code = response.statusCode;
                                     NSDictionary* status =
                                     [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:&error];
                                     if (!error)
                                         error = [NSError errorWithStatus:status code:code];
                                 }
                             } else {
                                 NSString* message =
                                 [NSString stringWithFormat:@"Bad response format for URL: %@",
                                  resp.URL.absoluteString];
                                 error = [NSError errorWithInfo:message
                                                           code:-10001];
                             }
                         }
                         if (completion)
                             completion(data, error);
                         
                     }] resume];
}

- (NSMutableURLRequest*)requestWithMethod:(NSString*)method
                                      url:(NSURL*)url
                                     data:(NSData*)data {
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPBody = data;
    request.HTTPMethod = method;
    [request setValue:_contentType forHTTPHeaderField:@"Content-Type"];
    
    return request;
}

- (void)handleDataRequestWithMethod:(NSString*)method
                                url:(NSURL*)url
                               data:(NSData*)data
                            handler:(void(^)(NSData* data, NSError* error))handler {
    
    NSMutableURLRequest* request = [self requestWithMethod:method
                                                       url:url
                                                      data:data];
    if (request) {
        
        [self dataWithRequest:request
                   completion:^(NSData* data, NSError* error) {
                       if (handler)
                           handler(data, error);
                   }];
    }
}

- (NSDictionary*)responseDictFromData:(NSData*)data
                         expectedCode:(NSUInteger)expectedCode
                                error:(NSError**)error {
    
    NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:data
                                                             options:NSJSONReadingAllowFragments
                                                               error:error];
    if (*error == nil) {
        NSString* code = jsonDict[@"code"];
        if (code && [code intValue] != expectedCode)
            *error = [NSError errorWithStatus:jsonDict[@"status"] code:[code intValue]];
    } else {
        *error = [NSError errorWithInfo:@"Bad response format" code:-10001];
    }
    return jsonDict;
}

@end
