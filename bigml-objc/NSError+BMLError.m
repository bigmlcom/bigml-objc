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

#import "NSError+BMLError.h"

@implementation NSError(BMLError)

+ (NSError*)errorWithInfo:(NSString*)errorString
                     code:(NSInteger)code
             extendedInfo:(NSDictionary*)extendedInfo {
    
    NSDictionary* userInfo = @{ NSLocalizedDescriptionKey:errorString,
                                BMLExtendedErrorDescriptionKey:extendedInfo?: @{} };
    
    return [NSError errorWithDomain:@"com.bigml.BigML"
                               code:code
                           userInfo:userInfo];
}

+ (NSError*)errorWithInfo:(NSString*)errorString
                     code:(NSInteger)code {
    
    return [self errorWithInfo:errorString code:code extendedInfo:@{}];
}

+ (NSDictionary*)dictFromRequest:(NSURLRequest*)request {

    NSDictionary*(^dictFromRequestHeaders)(NSURLRequest*) = ^NSDictionary*(NSURLRequest* r) {
        NSMutableDictionary* headers = [NSMutableDictionary new];
        for (NSString* header in request.allHTTPHeaderFields) {
            headers[header] = [request valueForHTTPHeaderField:header];
        }
        return headers;
    };
    
    return @{ @"Method" : [request HTTPMethod],
              @"URL" : request.URL.absoluteString,
              @"Headers" : dictFromRequestHeaders(request),
              @"Body" : [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]
              };
}

+ (NSError*)errorWithStatus:(NSDictionary*)status
                       code:(NSInteger)code
                 forRequest:(NSURLRequest*)request{
    
    NSString* info = status[@"message"] ?: @"Could not complete operation";
    NSMutableDictionary* extendedInfo = [status[@"extra"] ?: status ?: @{} mutableCopy];
    if (![extendedInfo isKindOfClass:[NSDictionary class]]) {
        extendedInfo = [@{@"extra" : extendedInfo} mutableCopy];
    }
    if (request) {
        extendedInfo[@"request"] = [self dictFromRequest:request];
    }
    return [NSError errorWithInfo:info code:code extendedInfo:extendedInfo];
}

@end
