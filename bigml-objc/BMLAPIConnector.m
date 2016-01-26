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

#import "BMLAPIConnector.h"
#import "BMLHTTPConnector.h"
#import "BMLResourceTypeIdentifier.h"
#import "NSError+BMLError.h"

void delay(float delay, dispatch_block_t block) {

    if (!block) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
}

@implementation BMLAPIConnector {
    
    BMLMode _mode;
    NSString* _authToken;
    
    BMLHTTPConnector* _connector;
}

+ (BMLAPIConnector*)connectorWithUsername:(NSString*)username
                                   apiKey:(NSString*)apiKey
                                     mode:(BMLMode)mode {
    
    return [[self alloc] initWithUsername:username apiKey:apiKey mode:mode];
}

- (instancetype)initWithUsername:(NSString*)username
                          apiKey:(NSString*)apiKey
                            mode:(BMLMode)mode {
    
    if (self = [super init]) {
        
        _connector = [BMLHTTPConnector new];
        _mode = mode;
        _authToken = [NSString stringWithFormat:@"username=%@;api_key=%@;",
                      username,
                      apiKey];
    }
    return self;
}

- (NSString*)fullUuidFromType:(BMLResourceTypeIdentifier*)type
                         uuid:(BMLResourceUuid*)uuid {
    return [NSString stringWithFormat:@"%@/%@", type.stringValue, uuid];
}

- (NSString*)serverUrl {
    
    NSString* url = [[NSUserDefaults standardUserDefaults]
                     stringForKey:@"bigMLAPIServerUrl"];
    return url ?: @"https://bigml.io";
}

- (NSURL*)authenticatedUrlFromUri:(NSString*)uri
                        arguments:(NSDictionary*)arguments {
    
    NSString* args = @"";
    for (NSString* key in arguments) {
        NSString* value = arguments[key];
        args = [NSString stringWithFormat:@"%@=%@;%@", key, value, args];
    }
    NSString* modeSelector = (_mode == BMLModeDevelopment) ? @"dev/" : @"";
    NSString* serverUrl = self.serverUrl;
    return [NSURL URLWithString:[NSString stringWithFormat:
                                 @"%@/%@andromeda/%@?%@%@",
                                 serverUrl,
                                 modeSelector,
                                 uri,
                                 _authToken,
                                 args]];
}

- (NSError*)withUri:(NSString*)uri
          arguments:(NSDictionary*)arguments
           runBlock:(void(^)(NSURL*))block {
    
    NSURL* url = [self authenticatedUrlFromUri:uri arguments:arguments];
    if (url) {
        if (block)
            block(url);
        return nil;
    }
    return [NSError
            errorWithInfo:@"Could not access server"
            code: -10100
            extendedInfo:@{@"Hint" : @"Please review user credentials and server URL"}];
}

- (void)createResourceCompletionBlock:(NSDictionary*)result
                                error:(NSError*)error
                           completion:(void(^)(id<BMLResource>, NSError*))completion {
    
    if (!error) {
        BMLMinimalResource* resource =
        [[BMLMinimalResource alloc] initWithName:result[@"name"]
                                        fullUuid:result[@"resource"]
                                      definition:@{}];
        [self trackResourceStatus:resource completion:completion];
    }
    if (error && completion)
        completion(nil, error);
}

- (void)createResource:(BMLResourceTypeIdentifier*)type
                  name:(NSString*)name
               options:(NSDictionary*)options
                  from:(id<BMLResource>)from
            completion:(void(^)(id<BMLResource>, NSError*))completion {
    
    NSAssert(type != nil, @"Wrong type passed to createResource:");
    NSError* e = [self withUri:type.stringValue arguments:@{} runBlock:^(NSURL* url) {
        
        if (from.type == BMLResourceTypeFile) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:from.uuid]) {
                
                [_connector uploadURL:url
                             filename:name
                             filepath:from.uuid
                                 body:options
                           completion:^(NSDictionary* dict, NSError* error) {
                               
                               [self createResourceCompletionBlock:dict
                                                             error:error
                                                        completion:completion];
                           }];
            } else {
                NSError* error = [NSError errorWithInfo:@"Input file not found"
                                                   code:-10301];
                [self createResourceCompletionBlock:@{}
                                              error:error
                                         completion:completion];
            }
        } else {
            
            NSMutableDictionary* body = [options mutableCopy] ?: [NSMutableDictionary new];
            [body setObject:name forKey:@"name"];
            if (from.type == type && type == BMLResourceTypeDataset) {
                [body setObject:from.fullUuid forKey:@"origin_dataset"];
            } else if (from.type != BMLResourceTypeProject &&
                       from.type != BMLResourceTypeWhizzmlSource) {
                [body setObject:from.fullUuid forKey:from.type.stringValue];
            }
            
            [_connector postURL:url
                           body:body
                     completion:^(NSDictionary* result, NSError* error) {
                         
                         [self createResourceCompletionBlock:result
                                                       error:error
                                                  completion:completion];
                     }];
        }
    }];
    
    if (e && completion)
        completion(nil, e);
}

- (void)createResource:(BMLResourceTypeIdentifier*)type
                  name:(NSString*)name
               options:(NSDictionary*)options
            completion:(void(^)(id<BMLResource>, NSError*))completion {
    
    NSError* e = [self withUri:type.stringValue arguments:@{} runBlock:^(NSURL* url){
        
        NSMutableDictionary* body = [options mutableCopy];
        [body setObject:name forKey:@"name"];
        
        [_connector postURL:url
                       body:body
                 completion:^(NSDictionary* result, NSError* error) {
                     
                     [self createResourceCompletionBlock:result
                                                   error:error
                                              completion:completion];
                 }];
    }];
    
    if (e && completion)
        completion(nil, e);
}

- (void)listResources:(BMLResourceTypeIdentifier*)type
              filters:(NSDictionary*)filters
           completion:(void(^)(NSArray*, NSError*))completion {
    
    NSError* e = [self withUri:type.stringValue arguments:@{} runBlock:^(NSURL* url){
        
        [_connector getURL:url
                completion:^(NSDictionary* dict, NSError* error) {
                    
                    NSMutableArray* resources = [NSMutableArray new];
                    if (!error) {
                        for (NSDictionary* resource in dict[@"objects"]) {
                            NSString* fullUuid = resource[@"resource"];
                            if (fullUuid) {
                                [resources addObject:
                                 [[BMLMinimalResource alloc] initWithName:resource[@"name"]
                                                                 fullUuid:fullUuid
                                                               definition:resource]];
                            } else {
                                error = [NSError errorWithInfo:@"Incomplete results"
                                                          code:-10105];
                                continue;
                            }
                        }
                    }
                    completion(resources, error);
                }];
    }];
    
    if (e && completion)
        completion(nil, e);
}

- (void)deleteResource:(BMLResourceTypeIdentifier*)type
                  uuid:(BMLResourceUuid*)uuid
            completion:(void(^)(NSError*))completion {
    
    NSError* e = [self withUri:[self fullUuidFromType:type uuid:uuid]
                     arguments:@{}
                      runBlock:^(NSURL* url) {
        
        [_connector deleteURL:url
                   completion:^(NSError* error) {
                       completion(error);
                   }];
    }];
    
    if (e && completion)
        completion(e);
}

- (void)updateResource:(BMLResourceTypeIdentifier*)type
                  uuid:(BMLResourceUuid*)uuid
                values:(NSDictionary*)values
            completion:(void(^)(NSError*))completion {
    
    NSError* e = [self withUri:[self fullUuidFromType:type uuid:uuid]
                     arguments:@{}
                      runBlock:^(NSURL* url){
        
        [_connector putURL:url
                      body:values
                completion:^(NSError* error) {
                    completion(error);
                }];
    }];
    
    if (e && completion)
        completion(e);
}

- (void)getIntermediateResource:(BMLResourceTypeIdentifier*)type
                           uuid:(BMLResourceUuid*)uuid
                     completion:(void(^)(NSDictionary*, NSError*))completion {
    
    NSError* e = [self withUri:[self fullUuidFromType:type uuid:uuid]
                     arguments:@{}
                      runBlock:^(NSURL* url) {
        
        [_connector getURL:url
                completion:^(NSDictionary* dict, NSError* error) {
                    
                    if (dict[@"code"]) {
                        int code = [dict[@"code"] intValue];
                        if (code != 200 &&
                            !(code == 500 && dict[@"resource_uri"] != nil)) {
                            
                            NSString* msg =
                            [NSString stringWithFormat:@"No data retrieved. Code: %d", code];
                            error = [NSError errorWithInfo:msg code:-10150];
                        }
                    } else {
                        error = [NSError errorWithInfo:@"Bad response format."
                                                  code:-10007];
                    }
                    if (completion)
                        completion(dict, error);
                }];
    }];
    
    if (e && completion)
        completion(nil, e);
}

- (void)getResource:(BMLResourceTypeIdentifier*)type
               uuid:(BMLResourceUuid*)uuid
         completion:(void(^)(id<BMLResource>, NSError*))completion {
    
    [self getIntermediateResource:type
                             uuid:uuid
                       completion:^(NSDictionary* dict, NSError* error) {
                           
                           BMLMinimalResource* resource = nil;
                           NSString* fullUuid = dict[@"resource"];
                           if (fullUuid) {
                               resource =
                               [[BMLMinimalResource alloc] initWithName:dict[@"name"]
                                                               fullUuid:fullUuid
                                                             definition:dict];
                           }
                           if (!resource && !error) {
                               error = [NSError errorWithInfo:@"Bad response format."
                                                         code:-10008];
                           }
                           if (completion)
                               completion(resource, error);
                       }];
}

- (void)trackResourceStatus:(id<BMLResource>)resource
                 completion:(void(^)(id<BMLResource>, NSError*))completion {
    
    if (resource.type == BMLResourceTypeProject) {
        if (completion)
            completion(resource, nil);
    } else {
        [self getIntermediateResource:resource.type
                                 uuid:resource.uuid
                           completion:^(NSDictionary* dict, NSError* error) {

                               if (!error) {
                                   NSDictionary* status = dict[@"status"];
                                   if (status[@"code"]) {
                                       int statusCode = [status[@"code"] shortValue];
                                       if (statusCode < BMLResourceStatusWaiting) {
                                           if (status[@"error"]) {
                                               error = [NSError errorWithStatus:status
                                                                           code:[status[@"error"] intValue]];
                                           }
                                           resource.status = BMLResourceStatusFailed;
                                       } else if (statusCode < BMLResourceStatusEnded) {
                                           delay(1.0, ^{[self trackResourceStatus:resource completion:completion];});
                                           if (resource.status != statusCode) {
                                               resource.status = statusCode;
                                               resource.progress = [status[@"progress"] floatValue];
                                           }
                                       } else if (statusCode == BMLResourceStatusEnded) {
                                           resource.status = statusCode;
                                           resource.jsonDefinition = dict;
                                           completion(resource, error);
                                       }
                                   } else {
                                       error = [NSError errorWithInfo:@"Bad response format."
                                                                 code:-10000];
                                   }
                               }
                               if (error) {
                                   resource.status = BMLResourceStatusFailed;
                                   completion(nil, error);
                               }
                           }];
    }
}

@end





























