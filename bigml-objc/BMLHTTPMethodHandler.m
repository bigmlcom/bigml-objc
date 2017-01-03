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

    [[self.session
      dataTaskWithRequest:request
                     completionHandler:^(NSData* data, NSURLResponse* resp, NSError* error) {
                         
                         if (!error) {
                             if ([resp isKindOfClass:[NSHTTPURLResponse class]]) {

                                 NSHTTPURLResponse* response = (id)resp;
                                 if (![response isStrictlyValid]) {
                                     
                                     NSUInteger code = response.statusCode;
                                     NSDictionary* status = [NSJSONSerialization
                                                             JSONObjectWithData:data
                                                             options:NSJSONReadingAllowFragments
                                                             error:&error];
                                     if (!error)
                                         error = [NSError errorWithStatus:status[@"status"] ?: status
                                                                     code:code
                                                               forRequest:nil];
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
    
    NSDictionary* jsonDict = nil;
    
    id jsonObject =
    [NSJSONSerialization
     JSONObjectWithData:data
     options:NSJSONReadingAllowFragments | NSJSONReadingMutableContainers
     error:error];
    
    //-- workaround for JSONObjectWithData failing with numbers formatted in scientific notation
    //-- (e.g., 1.0e-128). The regex below is tuned for probabilities. Beware of the risk of a
    //-- resource UUID matching some exponential number (e.g., ..0e12..)
    if (!jsonObject || *error) {
        
        *error = nil;
        NSString* json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSRegularExpression* regex = [NSRegularExpression
                                      regularExpressionWithPattern:@"(-?(?:0|[1-9]\\d*)(?:\\.\\d*)?(?:[eE]-\\d+))"
                                      options:NSRegularExpressionCaseInsensitive
                                      error:error];
        json = [regex stringByReplacingMatchesInString:json
                                               options:0
                                                 range:NSMakeRange(0, [json length])
                                          withTemplate:@"\"$0\""];
        
        NSData* d = [json dataUsingEncoding:NSUTF8StringEncoding];
        jsonObject =
        [NSJSONSerialization
         JSONObjectWithData:d
         options:NSJSONReadingAllowFragments | NSJSONReadingMutableContainers
         error:error];
        
#ifdef DEBUG
        if (!jsonObject) {
            NSLog(@"FAILED TO DECODE RESOURCE JSON: %@", json);
        }
#endif
    }
    
    if (*error == nil) {
        
        if ([jsonObject isKindOfClass:[NSDictionary class]]) {
            jsonDict = jsonObject;
            NSString* code = jsonDict[@"code"];
            if (code && [code intValue] != expectedCode)
                *error = [NSError errorWithStatus:jsonDict[@"status"]
                                             code:[code intValue]
                                       forRequest:nil];
        } else if([jsonObject isKindOfClass:[NSArray class]]) {
            
            NSMutableArray* keys = [NSMutableArray array];
            for (NSUInteger i = 0; i < [jsonObject count]; i++) {
                [keys addObject:@(i)];
            }
            jsonDict = [NSDictionary dictionaryWithObjects:jsonObject
                                                   forKeys:keys];
            
        } else {
            *error = [NSError errorWithInfo:@"Bad response format" code:-10002];
        }
        
    } else {
        
        *error = [NSError errorWithInfo:@"Bad response format" code:-10001];
    }
    return jsonDict;
}

@end
