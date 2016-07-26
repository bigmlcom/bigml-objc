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

@compatibility_alias BMLResourceUuid NSString;
@compatibility_alias BMLResourceFullUuid NSString;

@class BMLResourceTypeIdentifier;

/**
 * This protocol represents a generic BigML resource.
 */
@protocol BMLResource <NSObject>

/// the json body of the resource. See BigML REST API doc (https://tropo.dev.bigml.com/developers/)
@property (nonatomic, strong) NSDictionary* jsonDefinition;

/// the current status of the resource
@property (nonatomic) BMLResourceStatus status;

/// the resource name
- (NSString*)name;

/// the resource type
- (BMLResourceTypeIdentifier*)type;

/// the resource UUID
- (BMLResourceUuid*)uuid;

/// the resource full UUID
- (BMLResourceFullUuid*)fullUuid;

@end

@interface BMLMinimalResource : NSObject <BMLResource>

/**
 * Creates a BMLResource.
 * @param name The name to associate to the resource.
 * @param type the type of the resource to create.
 * @param uuid The UUID of the resource.
 * @param definition The JSON boby describing the resource.
 *  See BigML REST API doc (https://tropo.dev.bigml.com/developers/)
 * @returns An instance of BMLResource.
 */
- (instancetype)initWithName:(NSString*)name
                        type:(BMLResourceTypeIdentifier*)type
                        uuid:(BMLResourceUuid*)uuid
                  definition:(NSDictionary*)definition;

/**
 * Creates a BMLResource.
 * @param name The name to associate to the resource.
 * @param fullUuid The full UUID of the resource to create.
 * @param definition The JSON boby describing the resource.
 *  See BigML REST API doc (https://tropo.dev.bigml.com/developers/)
 * @returns An instance of BMLResource.
 */
- (instancetype)initWithName:(NSString*)name
                    fullUuid:(BMLResourceFullUuid*)fullUuid
                  definition:(NSDictionary*)definition;

@end
