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

#import <Foundation/Foundation.h>
#import "BMLEnums.h"
#import "BMLResourceProtocol.h"

@interface BMLAPIConnector : NSObject

- (instancetype)initWithUsername:(NSString*)username
                          apiKey:(NSString*)apiKey
                            mode:(BMLMode)mode
                         version:(NSString*)version;

+ (BMLAPIConnector*)connectorWithUsername:(NSString*)username
                                   apiKey:(NSString*)apiKey
                                     mode:(BMLMode)mode
                                  version:(NSString*)version;

- (void)createResource:(BMLResourceTypeIdentifier*)type
                  name:(NSString*)name
               options:(NSDictionary*)options
                  from:(id<BMLResource>)from
            completion:(void(^)(id<BMLResource>, NSError*))completion;

- (void)createResource:(BMLResourceTypeIdentifier*)type
                  name:(NSString*)name
               options:(NSDictionary*)options
            completion:(void(^)(id<BMLResource>, NSError*))completion;

- (void)listResources:(BMLResourceTypeIdentifier*)type
              filters:(NSDictionary*)filters
           completion:(void(^)(NSArray*, NSError*))completion;

- (void)deleteResource:(BMLResourceTypeIdentifier*)type
                  uuid:(BMLResourceUuid*)uuid
            completion:(void(^)(NSError*))completion;

- (void)updateResource:(BMLResourceTypeIdentifier*)type
                  uuid:(BMLResourceUuid*)uuid
                values:(NSDictionary*)values
            completion:(void(^)(NSError*))completion;

- (void)getResource:(BMLResourceTypeIdentifier*)type
               uuid:(BMLResourceUuid*)uuid
         completion:(void(^)(id<BMLResource>, NSError*))completion;

@end
