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

/**
 * Provides access to BigML REST API.
 *
 * Instantiate this class by providing your authorization credentials,
 * the use that instance to create a resource of any of the supported
 * types (see BMLResourceTypeIdentifier), list, update, and delete them.
 *
 */
@interface BMLAPIConnector : NSObject

/**
 * Allows you to authenticate with BigML using your username
 * and API Key.
 * @param username The username associated to your BigML account.
 * @param apiKey A valid apiKey.
 * @param mode Either BMLModeDevelopment or BMLModeProduction.
 * @param server The REST server to use, e.g., https://bigml-vpc.io, or nil for default.
 * @param version The API version to use; pass nil for default (currently andromeda)
 * @return an instance of BMLAPIConnector.
 */
- (instancetype)initWithUsername:(NSString*)username
                          apiKey:(NSString*)apiKey
                            mode:(BMLMode)mode
                          server:(NSString*)serverUrl
                         version:(NSString*)version;

/**
 * Convenience constructor for BMLAPIConnector.
 * @param username The username associated to your BigML account.
 * @param apiKey A valid apiKey.
 * @param mode Either BMLModeDevelopment or BMLModeProduction.
 * @param server The REST server to use, e.g., https://bigml-vpc.io, or nil for default.
 * @param version The API version to use; pass nil for default (currently andromeda)
 * @return an instance of BMLAPIConnector.
 */
+ (BMLAPIConnector*)connectorWithUsername:(NSString*)username
                                   apiKey:(NSString*)apiKey
                                     mode:(BMLMode)mode
                                   server:(NSString*)serverUrl
                                  version:(NSString*)version;

/**
 * Creates a remote resource on BigML.
 * @param type The type of the resource you want to create.
        See the BMLResourceTypeIdentifier class for a list of allowed types.
 * @param name The name of the resource.
 * @param options An NSDictionary containing the options. Check BigML REST API
 *  documentation (https://tropo.dev.bigml.com/developers) to learn about 
 *  available options.
 * @param from The resource to use to create the requested resource.
 * @param completion A completion block to handle the async response. The
 *  completion block has two arguments: the created resource and an NSError.
 */
- (void)createResource:(BMLResourceTypeIdentifier*)type
                  name:(NSString*)name
               options:(NSDictionary*)options
                  from:(id<BMLResource>)from
            completion:(void(^)(id<BMLResource>, NSError*))completion;

/**
 * Creates a remote resource on BigML. This is a convenience method
 * that provides a simplified signature so you do not need to pass nil
 * as the `from` argument for resources that are created on their own,
 * e.g., projects.
 * @param type The type of the resource you want to create.
 * See the BMLResourceTypeIdentifier class for a list of allowed types.
 * @param name The name of the resource.
 * @param options An NSDictionary containing the options. Check BigML REST API
 *  documentation (https://tropo.dev.bigml.com/developers) to learn about
 *  available options.
 * @param completion A completion block to handle the async response. The
 *  completion block has two arguments: the created resource and an NSError.
 */
- (void)createResource:(BMLResourceTypeIdentifier*)type
                  name:(NSString*)name
               options:(NSDictionary*)options
            completion:(void(^)(id<BMLResource>, NSError*))completion;

/**
 * Lists resources of a given type by filtering and ordering them according
 * to the specified criteria.
 * @param type The type of the resource you want to create.
 * See the BMLResourceTypeIdentifier class for a list of allowed types.
 * @param filters A dictionary containing the filtering and ordering options.
 * Check BigML REST API documentation (https://tropo.dev.bigml.com/developers)
 * to learn about available options.
 * @param completion A completion block to handle the async response. The
 *  completion block has two arguments: an array of resources and an NSError.
 */
- (void)listResources:(BMLResourceTypeIdentifier*)type
              filters:(NSDictionary*)filters
           completion:(void(^)(NSArray*, NSError*))completion;

/**
 * Deletes a specified resource.
 * @param type The type of the resource you want to create.
 * See the BMLResourceTypeIdentifier class for a list of allowed types.
 * @param uuid The uuid of the resource to delete.
 * @param completion A completion block to handle the async response. The
 *  completion block has one argument: an NSError.
 */
- (void)deleteResource:(BMLResourceTypeIdentifier*)type
                  uuid:(BMLResourceUuid*)uuid
            completion:(void(^)(NSError*))completion;

/**
 * Updates a specified resource.
 * @param type The type of the resource you want to create.
 * See the BMLResourceTypeIdentifier class for a list of allowed types.
 * @param uuid The uuid of the resource to delete.
 * @param values An NSDictionary containing the values you wish to update.
 * Check BigML REST API documentation (https://tropo.dev.bigml.com/developers)
 * to learn about mutable values.
 * @param completion A completion block to handle the async response. The
 *  completion block has one argument: an NSError.
 */
- (void)updateResource:(BMLResourceTypeIdentifier*)type
                  uuid:(BMLResourceUuid*)uuid
                values:(NSDictionary*)values
            completion:(void(^)(NSError*))completion;

/**
 * Retrieves a specified resource.
 * @param type The type of the resource you want to create.
 * See the BMLResourceTypeIdentifier class for a list of allowed types.
 * @param uuid The uuid of the resource to delete.
 * @param completion A completion block to handle the async response. The
 *  completion block has two arguments: the required resource and an NSError.
 */
- (void)getResource:(BMLResourceTypeIdentifier*)type
               uuid:(BMLResourceUuid*)uuid
         completion:(void(^)(id<BMLResource>, NSError*))completion;

@end
